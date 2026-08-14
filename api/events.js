export default async function handler(request, response) {
  if (request.method !== 'POST') {
    response.setHeader('Allow', 'POST');
    return response.status(405).json({error: 'Method not allowed'});
  }
  const backend = String(process.env.QR_AJN_BACKEND_URL || '').replace(/\/+$/, '');
  if (!backend) return response.status(204).end();
  const slug = String(request.body?.slug || '').trim().toLowerCase();
  const action = String(request.body?.action || '').trim();
  if (!/^[a-z0-9][a-z0-9_-]{2,47}$/.test(slug) || !/^[a-z_]{2,40}$/.test(action)) {
    return response.status(400).json({error: 'Invalid event'});
  }
  try {
    const upstream = await fetch(`${backend}/v1/business/events`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'user-agent': request.headers['user-agent'] || '',
        'referer': request.headers.referer || '',
        'x-vercel-ip-country': request.headers['x-vercel-ip-country'] || '',
      },
      body: JSON.stringify({slug, action}),
    });
    if (upstream.status === 202 || upstream.status === 204) return response.status(204).end();
    return response.status(upstream.status).json({error: 'Event was not accepted'});
  } catch {
    // Analytics must never break a public business page.
    return response.status(204).end();
  }
}
