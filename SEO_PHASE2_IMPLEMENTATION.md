# QR AJN SEO Phase 2

Generated: 2026-08-14T11:09:26.9267303+05:30
Domain: https://qrajn.online
Project: C:\Users\vigne\Documents\QR_AJN_COMPLETE_PRODUCTION_V6_1_0_BUSINESS_FIRST

## Added
- Server-rendered HTML for /b/<published-slug>
- Unique title, description, canonical, Open Graph and Twitter tags per profile
- WebPage + Organization + BreadcrumbList JSON-LD per profile
- 404/noindex handling for private/unpublished/missing profiles
- Thin-profile noindex guard
- Public published-profile backend endpoint with private fields omitted
- Indexable-profile directory endpoint
- Dynamic /sitemap-profiles.xml
- sitemap.xml sitemap index
- sitemap-static.xml
- Canonical redirects to /b/<slug>
- Breadcrumb verification/injection on static SEO pages
- Service-worker cache qrajn-v7-1-seo-v2-ssr

## Canonical public profile
https://qrajn.online/b/<slug>

## Sitemap
https://qrajn.online/sitemap.xml

## Dynamic profile sitemap
https://qrajn.online/sitemap-profiles.xml

## Important
The backend endpoint returns only published public profile fields. ownerUid and private dashboard/analytics data are not returned.

The dynamic profile sitemap currently caps at 5,000 quality published profiles. Increase/paginate it later if QR AJN grows beyond that number.

## Deployment
Cloud Run must be deployed before Vercel so the production QR_AJN_BACKEND_URL points at the backend containing the new public profile endpoints.