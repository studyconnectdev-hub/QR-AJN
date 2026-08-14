function cleanText(value, max = 500) {
  return typeof value === 'string' ? value.trim().slice(0, max) : '';
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function safeHttps(value) {
  try {
    const url = new URL(String(value || ''));
    return url.protocol === 'https:' ? url.toString() : '';
  } catch {
    return '';
  }
}

function jsonLd(value) {
  return JSON.stringify(value).replaceAll('<', '\\u003c');
}

function profileDescription(profile) {
  const name = cleanText(profile.name, 160) || 'QR AJN Business';
  const details = [
    cleanText(profile.title, 120),
    cleanText(profile.company, 120),
    cleanText(profile.address, 180),
  ].filter(Boolean);

  let value = details.length
    ? `${name} â€” ${details.join(' â€¢ ')}. View published contact and business information on QR AJN.`
    : `${name} digital business profile on QR AJN. View published contact and business information.`;

  if (value.length > 160) value = `${value.slice(0, 157).trimEnd()}...`;
  return value;
}

function errorPage(status, title, message, canonical) {
  const safeTitle = escapeHtml(title);
  const safeMessage = escapeHtml(message);
  const safeCanonical = escapeHtml(canonical);

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>${safeTitle}</title>
  <meta name="description" content="${safeMessage}">
  <meta name="robots" content="noindex,follow">
  <link rel="canonical" href="${safeCanonical}">
  <link rel="stylesheet" href="/styles.css">
  <link rel="icon" href="/app_icon_192.png">
</head>
<body>
  <div class="shell">
    <main class="public-wrap">
      <section class="panel">
        <h1>${safeTitle}</h1>
        <p class="muted">${safeMessage}</p>
        <a class="btn primary" href="/">Go to QR AJN</a>
      </section>
    </main>
  </div>
</body>
</html>`;
}

export default async function handler(request, response) {
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    response.setHeader('Allow', 'GET, HEAD');
    return response.status(405).send('Method not allowed');
  }

  const site = 'https://qrajn.online';
  const slug = String(request.query?.slug || '').trim().toLowerCase();

  if (!/^[a-z0-9][a-z0-9_-]{2,47}$/.test(slug)) {
    response.setHeader('Content-Type', 'text/html; charset=utf-8');
    response.setHeader('X-Robots-Tag', 'noindex, follow');
    return response
      .status(404)
      .send(errorPage(404, 'Profile not found | QR AJN', 'The requested QR AJN business profile could not be found.', `${site}/b/${encodeURIComponent(slug)}`));
  }

  const canonical = `${site}/b/${encodeURIComponent(slug)}`;
  const backend = String(process.env.QR_AJN_BACKEND_URL || '').replace(/\/+$/, '');

  if (!backend) {
    response.setHeader('Content-Type', 'text/html; charset=utf-8');
    response.setHeader('X-Robots-Tag', 'noindex, follow');
    return response
      .status(503)
      .send(errorPage(503, 'QR AJN profile temporarily unavailable', 'The public profile service is not configured yet.', canonical));
  }

  let upstream;
  try {
    upstream = await fetch(`${backend}/v1/public/business/${encodeURIComponent(slug)}`, {
      headers: {'accept': 'application/json'},
    });
  } catch {
    response.setHeader('Content-Type', 'text/html; charset=utf-8');
    response.setHeader('X-Robots-Tag', 'noindex, follow');
    return response
      .status(502)
      .send(errorPage(502, 'QR AJN profile temporarily unavailable', 'The public profile service could not be reached.', canonical));
  }

  if (upstream.status === 404) {
    response.setHeader('Content-Type', 'text/html; charset=utf-8');
    response.setHeader('X-Robots-Tag', 'noindex, follow');
    return response
      .status(404)
      .send(errorPage(404, 'Profile not found | QR AJN', 'This profile is private, unpublished, or does not exist.', canonical));
  }

  if (!upstream.ok) {
    response.setHeader('Content-Type', 'text/html; charset=utf-8');
    response.setHeader('X-Robots-Tag', 'noindex, follow');
    return response
      .status(503)
      .send(errorPage(503, 'QR AJN profile temporarily unavailable', 'The profile could not be loaded right now.', canonical));
  }

  const profile = await upstream.json();
  const name = cleanText(profile.name, 160) || 'QR AJN Business';
  const titleText = cleanText(profile.title, 160);
  const company = cleanText(profile.company, 160);
  const address = cleanText(profile.address, 1000);
  const services = Array.isArray(profile.services)
    ? profile.services.map((item) => cleanText(item, 240)).filter(Boolean).slice(0, 20)
    : [];

  const indexable =
    name !== 'QR AJN Business' &&
    Boolean(titleText || company || address || services.length > 0);

  const robots = indexable
    ? 'index,follow,max-image-preview:large'
    : 'noindex,follow';

  const pageTitle = `${name} | QR AJN Business Profile`;
  const description = profileDescription(profile);
  const image =
    safeHttps(profile.logoUrl) ||
    safeHttps(profile.photoUrl) ||
    `${site}/app_icon_192.png`;
  const website = safeHttps(profile.website);

  const graph = [
    {
      '@type': 'WebPage',
      '@id': `${canonical}#webpage`,
      url: canonical,
      name: pageTitle,
      description,
      isPartOf: {'@id': `${site}/#website`},
    },
    {
      '@type': 'BreadcrumbList',
      itemListElement: [
        {
          '@type': 'ListItem',
          position: 1,
          name: 'QR AJN',
          item: `${site}/`,
        },
        {
          '@type': 'ListItem',
          position: 2,
          name,
          item: canonical,
        },
      ],
    },
    {
      '@type': 'Organization',
      '@id': `${canonical}#business`,
      name,
      url: canonical,
      ...(website ? {sameAs: [website]} : {}),
      ...(image ? {logo: image} : {}),
      ...(services.length ? {knowsAbout: services.slice(0, 10)} : {}),
    },
  ];

  const structuredData = {
    '@context': 'https://schema.org',
    '@graph': graph,
  };

  const safeName = escapeHtml(name);
  const safeTitleText = escapeHtml(titleText);
  const safeCompany = escapeHtml(company);
  const safeAddress = escapeHtml(address);
  const safeDescription = escapeHtml(description);
  const safePageTitle = escapeHtml(pageTitle);
  const safeImage = escapeHtml(image);
  const serviceHtml = services.length
    ? `<section class="card"><h2>Services</h2><ul>${services
        .slice(0, 12)
        .map((item) => `<li>${escapeHtml(item)}</li>`)
        .join('')}</ul></section>`
    : '';

  const html = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
  <title>${safePageTitle}</title>
  <meta name="description" content="${safeDescription}">
  <meta name="robots" content="${robots}">
  <link rel="canonical" href="${canonical}">
  <meta property="og:site_name" content="QR AJN">
  <meta property="og:type" content="profile">
  <meta property="og:title" content="${safePageTitle}">
  <meta property="og:description" content="${safeDescription}">
  <meta property="og:url" content="${canonical}">
  <meta property="og:image" content="${safeImage}">
  <meta name="twitter:card" content="summary">
  <meta name="twitter:title" content="${safePageTitle}">
  <meta name="twitter:description" content="${safeDescription}">
  <meta name="twitter:image" content="${safeImage}">
  <meta name="theme-color" content="#2563eb">
  <link rel="manifest" href="/manifest.webmanifest">
  <link rel="icon" href="/app_icon_192.png">
  <link rel="stylesheet" href="/styles.css">
  <script type="application/ld+json">${jsonLd(structuredData)}</script>
</head>
<body>
  <div id="app">
    <div class="shell">
      <header class="topbar">
        <a class="brand" href="/">
          <img src="/app_icon_192.png" alt="QR AJN">
          <span><strong>QR AJN</strong><small>Digital Business Identity</small></span>
        </a>
      </header>
      <main class="public-wrap">
        <section class="panel">
          <span class="status">Published QR AJN profile</span>
          <h1>${safeName}</h1>
          ${safeTitleText ? `<p><strong>${safeTitleText}</strong></p>` : ''}
          ${safeCompany ? `<p class="muted">${safeCompany}</p>` : ''}
          ${safeAddress ? `<p class="muted">${safeAddress}</p>` : ''}
          <p class="muted">${safeDescription}</p>
        </section>
        ${serviceHtml}
      </main>
    </div>
  </div>
  <script type="module" src="/app.js"></script>
  <script>
    if ('serviceWorker' in navigator) {
      addEventListener('load', () => navigator.serviceWorker.register('/sw.js').catch(() => {}));
    }
  </script>
</body>
</html>`;

  response.setHeader('Content-Type', 'text/html; charset=utf-8');
  response.setHeader(
    'Cache-Control',
    indexable
      ? 'public, s-maxage=300, stale-while-revalidate=3600'
      : 'public, s-maxage=60, stale-while-revalidate=300',
  );
  response.setHeader('X-Robots-Tag', robots);

  if (request.method === 'HEAD') return response.status(200).end();
  return response.status(200).send(html);
}