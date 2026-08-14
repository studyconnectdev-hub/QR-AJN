QR AJN SEO V1 IMPLEMENTATION
Generated: 2026-08-14T10:51:59.4119953+05:30
Domain: https://qrajn.online
Project: C:\Users\vigne\Documents\QR_AJN_COMPLETE_PRODUCTION_V6_1_0_BUSINESS_FIRST

ADDED
- Improved homepage title and description
- Homepage canonical
- Open Graph and Twitter metadata
- WebSite JSON-LD
- Organization JSON-LD
- Static indexable SEO landing pages
- Breadcrumb structured data on landing pages
- Clean robots.txt
- Canonical public-only sitemap.xml
- Permanent canonical redirects for public profile aliases
- X-Robots-Tag noindex for private/product-app routes
- Dynamic title/description/canonical for published /b/slug profiles
- noindex metadata for unavailable/private SPA profile states
- Internal links between SEO pages
- Service-worker cache refresh

INDEXABLE
/
 /about
 /digital-business-card
 /business-qr-code
 /dynamic-qr-code
 /qr-code-generator
 /qr-code-scanner
 /qr-code-safety
 /faq
 /help
 /privacy
 /b/<published-slug>

NOINDEX
/login
/builder
/dashboard
/dynamic
/analytics
/admin
/contact
/pricing
/blog
/r/<code>
/q/<code>

NEXT
1. Deploy web_dashboard to the existing Vercel project.
2. Verify qrajn.online as a Domain property in Google Search Console using DNS TXT.
3. Submit https://qrajn.online/sitemap.xml.
4. Inspect the homepage and important landing pages in Search Console.
5. For strongest SEO on /b/<slug>, move public profiles to server-side or prerendered HTML in a later phase.