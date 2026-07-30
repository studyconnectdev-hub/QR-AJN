import admin from 'firebase-admin';

if (!admin.apps.length) admin.initializeApp();
export const db = admin.firestore();

function numberOrNull(value) {
  if (value == null || value === '') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

export async function createDynamicLink(data) {
  const ref = data.code
    ? db.collection('dynamic_links').doc(String(data.code))
    : db.collection('dynamic_links').doc();
  const expiresAt = data.expiresAt
    ? admin.firestore.Timestamp.fromDate(new Date(data.expiresAt))
    : null;
  const maximumScans = numberOrNull(data.maximumScans ?? data.maxScans);

  await ref.set({
    ownerUid: data.ownerUid || null,
    title: String(data.title || data.label || 'Dynamic QR').slice(0, 120),
    destination: data.destination,
    androidDestination: data.androidDestination || '',
    iosDestination: data.iosDestination || '',
    desktopDestination: data.desktopDestination || '',
    fallbackDestination: data.fallbackDestination || '',
    active: data.active !== false,
    expiresAt,
    maximumScans,
    // Keep maxScans for backward compatibility with earlier backend clients.
    maxScans: maximumScans,
    scanCount: numberOrNull(data.scanCount) ?? 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  return {id: ref.id, code: ref.id, shortPath: `/r/${ref.id}`};
}

export async function resolveLinkForRedirect(id) {
  const ref = db.collection('dynamic_links').doc(String(id).toUpperCase());
  return db.runTransaction(async transaction => {
    let snap = await transaction.get(ref);

    // Backend-generated IDs are case-sensitive. Retry the supplied value as-is.
    if (!snap.exists && String(id) !== String(id).toUpperCase()) {
      const fallbackRef = db.collection('dynamic_links').doc(String(id));
      const fallbackSnap = await transaction.get(fallbackRef);
      if (fallbackSnap.exists) {
        snap = fallbackSnap;
      }
    }

    if (!snap.exists) return {status: 'missing'};

    const data = snap.data();
    if (data.active === false) return {status: 'inactive'};
    if (data.expiresAt?.toDate && data.expiresAt.toDate() < new Date()) {
      return {status: 'expired'};
    }

    const maximumScans = numberOrNull(data.maximumScans ?? data.maxScans);
    const scanCount = numberOrNull(data.scanCount) ?? 0;
    if (maximumScans != null && scanCount >= maximumScans) {
      return {status: 'limit_reached'};
    }

    transaction.update(snap.ref, {
      scanCount: admin.firestore.FieldValue.increment(1),
      lastScannedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      status: 'ok',
      id: snap.id,
      ...data,
      maximumScans,
      scanCount: scanCount + 1,
    };
  });
}
