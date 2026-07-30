import http from 'node:http';
import crypto from 'node:crypto';
import {expandPublicUrl, safeJson, setCommonHeaders, validatePublicUrl} from './security.js';
import {db, createDynamicLink, resolveLinkForRedirect} from './store.js';
import {verifyGooglePlaySubscription} from './billing.js';

const port = Number(process.env.PORT || 8080);
const rateBuckets = new Map();

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
    if (req.method === 'OPTIONS') { setCommonHeaders(res); res.writeHead(204); return res.end(); }
    rateLimit(req, url.pathname.startsWith('/r/') ? 240 : 60);

    if (req.method === 'GET' && url.pathname === '/health') return safeJson(res, 200, {ok:true, service:'qr-ajn-backend', version:'4.0.0'});

    const redirectMatch = url.pathname.match(/^\/r\/([A-Za-z0-9_-]+)$/);
    if (req.method === 'GET' && redirectMatch) {
      const result = await resolveLinkForRedirect(redirectMatch[1]);
      if (result.status === 'missing' || result.status === 'inactive') return safeJson(res, 404, {error:'Link not found or inactive'});
      if (result.status === 'expired') return safeJson(res, 410, {error:'Link expired'});
      if (result.status === 'limit_reached') return safeJson(res, 410, {error:'Scan limit reached'});
      const validated = await validatePublicUrl(result.destination);
      queueScanEvent(result.id, req).catch(() => {});
      setCommonHeaders(res);
      res.writeHead(302, {location:validated.url.toString()});
      return res.end();
    }

    if (req.method === 'GET' && url.pathname === '/v1/dashboard/metrics') {
      requireAdmin(req);
      const [links, scans, tickets, products] = await Promise.all([
        countCollection('dynamic_links'), countCollection('scan_events'), countQuery('tickets', 'redeemedAt'), countCollection('product_verification_events'),
      ]);
      return safeJson(res, 200, {dynamicLinks:links, scanEvents:scans, redeemedTickets:tickets, productVerifications:products});
    }

    if (req.method === 'POST' && url.pathname === '/v1/links') {
      requireAdmin(req);
      const body = await readJson(req);
      const validated = await validatePublicUrl(body.destination);
      const expiresAt = optionalFutureIso(body.expiresAt);
      const maxScans = optionalPositiveInteger(body.maxScans);
      const result = await createDynamicLink({destination:validated.url.toString(), label:String(body.label || '').slice(0,120), expiresAt, maxScans});
      return safeJson(res, 201, result);
    }

    if (req.method === 'POST' && url.pathname === '/v1/security/inspect') {
      requireAdmin(req);
      const body = await readJson(req);
      const target = await validatePublicUrl(body.url);
      return safeJson(res, 200, {safeToRequest:true, scheme:target.url.protocol, host:target.url.hostname, resolvedAddresses:target.records.map(item => maskAddress(item.address)), note:'Network-safety validation passed. Connect an approved reputation provider for malware/phishing verdicts.'});
    }

    if (req.method === 'POST' && url.pathname === '/v1/security/expand') {
      requireAdmin(req);
      const body = await readJson(req);
      return safeJson(res, 200, await expandPublicUrl(body.url));
    }

    if (req.method === 'POST' && url.pathname === '/v1/billing/google-play/verify') {
      const identity = await requireFirebaseUser(req);
      const body = await readJson(req);
      return safeJson(res, 200, await verifyGooglePlaySubscription({...body, userId: identity.uid}));
    }

    if (req.method === 'POST' && url.pathname === '/v1/inventory/events') { requireAdmin(req); return createEvent(res, req, 'inventory_events'); }
    if (req.method === 'POST' && url.pathname === '/v1/attendance/events') { requireAdmin(req); return createEvent(res, req, 'attendance_events'); }
    if (req.method === 'POST' && url.pathname === '/v1/tickets/redeem') { requireAdmin(req); return redeemTicket(res, req); }
    if (req.method === 'POST' && url.pathname === '/v1/products/verify') return verifyProduct(res, req);
    if (req.method === 'POST' && url.pathname === '/v1/subscriptions/entitlements') { requireAdmin(req); return entitlement(res, req); }

    safeJson(res, 404, {error:'Not found'});
  } catch (error) {
    const status = Number(error.statusCode || 400);
    safeJson(res, status, {error:error.message || 'Request failed'});
  }
});

async function requireFirebaseUser(req) {
  const authorization = String(req.headers.authorization || '');
  if (!authorization.startsWith('Bearer ')) {
    const error = new Error('Firebase user authorization required');
    error.statusCode = 401;
    throw error;
  }
  try {
    return await (await import('firebase-admin')).default.auth().verifyIdToken(authorization.slice(7));
  } catch {
    const error = new Error('Invalid or expired Firebase user token');
    error.statusCode = 401;
    throw error;
  }
}

function requireAdmin(req) {
  const expected = process.env.ADMIN_API_KEY || '';
  const provided = String(req.headers['x-admin-key'] || '');
  if (!expected || !constantTimeEqual(expected, provided)) {
    const error = new Error('Administrator authorization required');
    error.statusCode = 401;
    throw error;
  }
}

function constantTimeEqual(left, right) {
  const a = Buffer.from(left);
  const b = Buffer.from(right);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

function rateLimit(req, limit) {
  const ip = String(req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown').split(',')[0].trim();
  const minute = Math.floor(Date.now() / 60000);
  const key = `${minute}:${ip}`;
  const count = (rateBuckets.get(key) || 0) + 1;
  rateBuckets.set(key, count);
  if (rateBuckets.size > 5000) for (const item of rateBuckets.keys()) if (!item.startsWith(`${minute}:`)) rateBuckets.delete(item);
  if (count > limit) { const error = new Error('Rate limit exceeded'); error.statusCode = 429; throw error; }
}

async function createEvent(res, req, collection) {
  const body = await readJson(req);
  const ref = await db.collection(collection).add({...body, createdAt:new Date(), requestId:crypto.randomUUID()});
  return safeJson(res, 201, {id:ref.id});
}

async function redeemTicket(res, req) {
  const {ticketId} = await readJson(req);
  if (!ticketId) throw new Error('ticketId is required');
  const ref = db.collection('tickets').doc(String(ticketId));
  const result = await db.runTransaction(async transaction => {
    const snap = await transaction.get(ref);
    if (!snap.exists) return {status:'unknown'};
    if (snap.data().redeemedAt) return {status:'already_redeemed'};
    transaction.update(ref, {redeemedAt:new Date()});
    return {status:'redeemed'};
  });
  return safeJson(res, 200, result);
}

async function verifyProduct(res, req) {
  const {serial} = await readJson(req);
  if (!serial) throw new Error('serial is required');
  const normalized = String(serial).trim().slice(0,180);
  const snap = await db.collection('products').doc(normalized).get();
  await db.collection('product_verification_events').add({serialHash:crypto.createHash('sha256').update(normalized).digest('hex'), status:snap.exists ? 'genuine' : 'unknown', createdAt:new Date()});
  return safeJson(res, 200, snap.exists ? {status:'genuine', product:snap.data()} : {status:'unknown'});
}

async function entitlement(res, req) {
  const {installationId} = await readJson(req);
  if (!installationId) throw new Error('installationId is required');
  const snap = await db.collection('entitlements').doc(String(installationId)).get();
  return safeJson(res, 200, snap.exists ? snap.data() : {plan:'free', active:true});
}

async function queueScanEvent(linkId, req) {
  const ip = String(req.headers['x-forwarded-for'] || '').split(',')[0].trim();
  const dailySalt = new Date().toISOString().slice(0,10);
  const ipHash = ip ? crypto.createHash('sha256').update(`${dailySalt}:${ip}`).digest('hex') : null;
  await db.collection('scan_events').add({linkId, ipHash, userAgent:String(req.headers['user-agent'] || '').slice(0,300), createdAt:new Date()});
}

async function countCollection(collection) {
  const snapshot = await db.collection(collection).count().get();
  return snapshot.data().count;
}

async function countQuery(collection, field) {
  const snapshot = await db.collection(collection).where(field, '!=', null).count().get();
  return snapshot.data().count;
}

async function readJson(req) {
  let raw = '';
  for await (const chunk of req) {
    raw += chunk;
    if (raw.length > 1_000_000) { const error = new Error('Body too large'); error.statusCode = 413; throw error; }
  }
  try { return raw ? JSON.parse(raw) : {}; } catch { throw new Error('Invalid JSON body'); }
}

function optionalFutureIso(value) {
  if (value == null || value === '') return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime()) || date <= new Date()) throw new Error('expiresAt must be a future ISO date');
  return date.toISOString();
}

function optionalPositiveInteger(value) {
  if (value == null || value === '') return null;
  const number = Number(value);
  if (!Number.isInteger(number) || number < 1 || number > 1_000_000_000) throw new Error('maxScans must be a positive integer');
  return number;
}

function maskAddress(address) {
  if (address.includes(':')) return `${address.slice(0, 8)}…`;
  const parts = address.split('.');
  return `${parts[0]}.${parts[1]}.x.x`;
}

server.listen(port, () => console.log(`QR AJN backend listening on ${port}`));
