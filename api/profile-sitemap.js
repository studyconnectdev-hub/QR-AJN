function xmlEscape(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
}

export default async function handler(request, response) {
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    response.setHeader('Allow', 'GET, HEAD');
    return response.status(405).send('Method not allowed');
  }

  const site = 'https://qrajn.online';
  const backend = String(process.env.QR_AJN_BACKEND_URL || '').replace(/\/+$/, '');

  if (!backend) {
    response.setHeader('Content-Type', 'application/xml; charset=utf-8');
    return response.status(503).send('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"></urlset>');
  }

  try {
    const upstream = await fetch(`${backend}/v1/public/business-directory`, {
      headers: {'accept': 'application/json'},
    });

    if (!upstream.ok) throw new Error(`backend ${upstream.status}`);

    const body = await upstream.json();
    const profiles = Array.isArray(body.profiles) ? body.profiles : [];

    const entries = profiles
      .filter((item) => /^[a-z0-9][a-z0-9_-]{2,47}$/.test(String(item?.slug || '')))
      .slice(0, 5000)
      .map((item) => {
        const loc = `${site}/b/${encodeURIComponent(item.slug)}`;
        const lastmod =
          typeof item.updatedAt === 'string' && /^\d{4}-\d{2}-\d{2}T/.test(item.updatedAt)
            ? `<lastmod>${xmlEscape(item.updatedAt)}</lastmod>`
            : '';
        return `  <url><loc>${xmlEscape(loc)}</loc>${lastmod}</url>`;
      })
      .join('\n');

    const xml =
      `<?xml version="1.0" encoding="UTF-8"?>\n` +
      `<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n` +
      `${entries}\n` +
      `</urlset>\n`;

    response.setHeader('Content-Type', 'application/xml; charset=utf-8');
    response.setHeader('Cache-Control', 'public, s-maxage=600, stale-while-revalidate=3600');
    response.setHeader('X-Robots-Tag', 'noindex');

    if (request.method === 'HEAD') return response.status(200).end();
    return response.status(200).send(xml);
  } catch {
    response.setHeader('Content-Type', 'application/xml; charset=utf-8');
    response.setHeader('Cache-Control', 'no-store');
    return response.status(503).send('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"></urlset>');
  }
}