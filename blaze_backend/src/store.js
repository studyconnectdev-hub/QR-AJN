import admin from 'firebase-admin';
if (!admin.apps.length) admin.initializeApp();
export const db = admin.firestore();

export async function createDynamicLink(data) {
  const ref = db.collection('dynamic_links').doc();
  const expiresAt = data.expiresAt ? admin.firestore.Timestamp.fromDate(new Date(data.expiresAt)) : null;
  await ref.set({
    destination:data.destination,
    label:data.label,
    active:true,
    expiresAt,
    maxScans:data.maxScans ?? null,
    scanCount:0,
    createdAt:admin.firestore.FieldValue.serverTimestamp(),
    updatedAt:admin.firestore.FieldValue.serverTimestamp(),
  });
  return {id:ref.id, shortPath:`/r/${ref.id}`};
}

export async function resolveLinkForRedirect(id) {
  const ref = db.collection('dynamic_links').doc(id);
  return db.runTransaction(async transaction => {
    const snap = await transaction.get(ref);
    if (!snap.exists) return {status:'missing'};
    const data = snap.data();
    if (!data.active) return {status:'inactive'};
    if (data.expiresAt?.toDate && data.expiresAt.toDate() < new Date()) return {status:'expired'};
    if (Number.isFinite(data.maxScans) && Number(data.scanCount || 0) >= Number(data.maxScans)) return {status:'limit_reached'};
    transaction.update(ref, {scanCount:admin.firestore.FieldValue.increment(1), lastScannedAt:admin.firestore.FieldValue.serverTimestamp()});
    return {status:'ok', id:snap.id, ...data};
  });
}
