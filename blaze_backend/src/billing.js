import {google} from 'googleapis';
import admin from 'firebase-admin';
import {db} from './store.js';

const packageName = process.env.ANDROID_PACKAGE_NAME || 'com.qr.ajn';
const allowedProducts = new Set([
  process.env.PREMIUM_MONTHLY_ID || 'qrajn_pro_monthly',
  process.env.PREMIUM_YEARLY_ID || 'qrajn_pro_yearly',
  process.env.BUSINESS_MONTHLY_ID || 'qrajn_business_monthly',
  process.env.BUSINESS_YEARLY_ID || 'qrajn_business_yearly',
]);

export async function verifyGooglePlaySubscription({userId, productId, purchaseToken}) {
  if (!userId || !productId || !purchaseToken) {
    throw new Error('userId, productId and purchaseToken are required');
  }
  if (!allowedProducts.has(String(productId))) {
    throw new Error('Unknown QR AJN product ID');
  }

  const auth = new google.auth.GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  const publisher = google.androidpublisher({version: 'v3', auth});
  const response = await publisher.purchases.subscriptionsv2.get({
    packageName,
    token: String(purchaseToken),
  });

  const lineItems = Array.isArray(response.data.lineItems) ? response.data.lineItems : [];
  const matching = lineItems.find((item) => item.productId === productId) || lineItems[0];
  const expiryTime = matching?.expiryTime ? new Date(matching.expiryTime) : null;
  const state = String(response.data.subscriptionState || '');
  const activeStates = new Set([
    'SUBSCRIPTION_STATE_ACTIVE',
    'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
  ]);
  const active = activeStates.has(state) && expiryTime instanceof Date && !Number.isNaN(expiryTime.getTime()) && expiryTime > new Date();
  const plan = String(productId).includes('business') ? 'business' : 'pro';

  const entitlement = {
    active,
    plan: active ? plan : 'free',
    productId,
    subscriptionState: state,
    expiryTime: expiryTime ? admin.firestore.Timestamp.fromDate(expiryTime) : null,
    latestOrderId: response.data.latestOrderId || null,
    acknowledged: response.data.acknowledgementState === 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED',
    verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  await db.collection('entitlements').doc(String(userId)).set(entitlement, {merge: true});
  return {...entitlement, expiryTime: expiryTime?.toISOString() ?? null};
}
