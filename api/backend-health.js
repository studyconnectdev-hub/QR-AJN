export default async function handler(_request, response) {
  const backend = String(process.env.QR_AJN_BACKEND_URL || '').replace(/\/+$/, '');
  if (!backend) return response.status(503).json({ok: false, configured: false});
  try {
    const upstream = await fetch(`${backend}/health`, {headers: {'accept': 'application/json'}});
    const body = await upstream.json().catch(() => ({ok: false}));
    return response.status(upstream.ok ? 200 : 503).json({...body, configured: true});
  } catch {
    return response.status(503).json({ok: false, configured: true});
  }
}
