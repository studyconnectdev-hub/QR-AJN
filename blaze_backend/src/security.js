import dns from 'node:dns/promises';
import net from 'node:net';
import http from 'node:http';
import https from 'node:https';

export function setCommonHeaders(res) {
  const allowedOrigin = process.env.ALLOWED_ORIGIN || '*';
  res.setHeader('access-control-allow-origin', allowedOrigin);
  res.setHeader('access-control-allow-headers', 'content-type,x-admin-key,authorization');
  res.setHeader('access-control-allow-methods', 'GET,POST,OPTIONS');
  res.setHeader('cache-control', 'no-store');
  res.setHeader('x-content-type-options', 'nosniff');
  res.setHeader('referrer-policy', 'no-referrer');
  res.setHeader('content-security-policy', "default-src 'none'; frame-ancestors 'none'");
}

export function safeJson(res, status, body) {
  setCommonHeaders(res);
  res.writeHead(status, {'content-type':'application/json; charset=utf-8'});
  res.end(JSON.stringify(body));
}

export async function validatePublicUrl(value) {
  if (typeof value !== 'string' || value.length > 4096) throw new Error('A valid URL is required');
  const url = new URL(value);
  if (!['http:', 'https:'].includes(url.protocol)) throw new Error('Only HTTP/HTTPS destinations are allowed');
  if (url.username || url.password) throw new Error('Embedded credentials are not allowed');
  if (!url.hostname || url.hostname.length > 253) throw new Error('Invalid host');
  const records = await dns.lookup(url.hostname, {all:true, verbatim:true});
  if (!records.length || records.some((item) => isPrivateIp(item.address))) throw new Error('Private or unresolved destinations are blocked');
  return {url, records};
}

export async function expandPublicUrl(value, maxRedirects = 5) {
  let current = String(value);
  const chain = [];
  for (let index = 0; index <= maxRedirects; index += 1) {
    const validated = await validatePublicUrl(current);
    chain.push(validated.url.toString());
    const response = await pinnedHeadRequest(validated.url, validated.records[0]);
    if (response.statusCode >= 300 && response.statusCode < 400 && response.location) {
      current = new URL(response.location, validated.url).toString();
      continue;
    }
    return {finalUrl:validated.url.toString(), chain, statusCode:response.statusCode};
  }
  throw new Error('Too many redirects');
}

function pinnedHeadRequest(url, record) {
  return new Promise((resolve, reject) => {
    const transport = url.protocol === 'https:' ? https : http;
    const request = transport.request(url, {
      method:'HEAD',
      timeout:6000,
      headers:{'user-agent':'PrivateSafeQR-Security/1.0','accept':'*/*'},
      servername:url.hostname,
      lookup:(_hostname, _options, callback) => callback(null, record.address, record.family),
    }, response => {
      response.resume();
      resolve({statusCode:response.statusCode || 0, location:response.headers.location || null});
    });
    request.on('timeout', () => request.destroy(new Error('Destination timed out')));
    request.on('error', reject);
    request.end();
  });
}

export function isPrivateIp(ip) {
  if (net.isIPv4(ip)) {
    const parts = ip.split('.').map(Number);
    const [a,b,c] = parts;
    return a === 10 || a === 127 || a === 0 ||
      (a === 100 && b >= 64 && b <= 127) ||
      (a === 169 && b === 254) ||
      (a === 172 && b >= 16 && b <= 31) ||
      (a === 192 && b === 0 && c === 0) ||
      (a === 192 && b === 0 && c === 2) ||
      (a === 192 && b === 168) ||
      (a === 198 && (b === 18 || b === 19)) ||
      (a === 198 && b === 51 && c === 100) ||
      (a === 203 && b === 0 && c === 113) ||
      a >= 224;
  }
  const normalized = ip.toLowerCase();
  return normalized === '::' || normalized === '::1' || normalized.startsWith('fc') ||
    normalized.startsWith('fd') || normalized.startsWith('fe80:') || normalized.startsWith('ff') ||
    normalized.startsWith('2001:db8:');
}
