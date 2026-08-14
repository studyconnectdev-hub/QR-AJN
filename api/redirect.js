export default async function handler(request, response) {
  const code = String(request.query?.code || '').trim();
  if (!/^[A-Za-z0-9_-]{3,64}$/.test(code)) {
    return response.status(400).json({error: 'Invalid QR code'});
  }
  const backend = String(process.env.QR_AJN_BACKEND_URL || '').replace(/\/+$/, '');
  if (!backend) {
    return response.status(503).json({error: 'QR AJN redirect backend is not configured'});
  }
  try {
    const upstream = await fetch(`${backend}/r/${encodeURIComponent(code)}`, {
      method: 'GET',
      redirect: 'manual',
      headers: {
        'user-agent': request.headers['user-agent'] || '',
        'referer': request.headers.referer || '',
        'x-vercel-ip-country': request.headers['x-vercel-ip-country'] || '',
      },
    });
    const location = upstream.headers.get('location');
    if (location && upstream.status >= 300 && upstream.status < 400) {
      response.setHeader('Cache-Control', 'no-store');
      return response.redirect(upstream.status, location);
    }
    const text = await upstream.text();
    response.status(upstream.status);
    response.setHeader('Cache-Control', 'no-store');
    response.setHeader('Content-Type', upstream.headers.get('content-type') || 'application/json; charset=utf-8');
    return response.send(text);
  } catch (error) {
    return response.status(502).json({error: 'QR AJN redirect backend is unavailable'});
  }
}
