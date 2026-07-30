# QR AJN V4 Production Architecture

## Mobile
Flutter Android package `com.qr.ajn`.

Core local services:
- Camera scanning and multiple-code target selection
- Smart parser and UPI/deep-link action routing
- Local SafeScan rules
- QR payload generation and quality scoring
- PNG/PDF/SVG export
- Local settings

Optional cloud services:
- Firebase Authentication for business accounts
- Firestore profiles, dynamic links, entitlements and receipt queue
- Remote Config safety/feature controls
- App Check, Crashlytics, Performance, FCM and optional Analytics
- AdMob for free users
- Google Play Billing for Pro/Business plans

## Website
Firebase Hosting serves:
- `qrajn.online`
- Public business profiles: `/@slug`
- Client-side Spark dynamic links: `/q/code`
- Profile builder and sign-in
- Privacy and account-deletion pages

## Optional Blaze backend
Cloud Run provides secure server redirects, scan analytics, SSRF-safe URL expansion, ticket/product workflows and Google Play purchase verification.

## Security boundaries
- No automatic scan history
- External actions require preview/confirmation
- UPI PINs are never requested
- Upload keys and service-account credentials are excluded from Git
- Spark dynamic links are convenient but not a substitute for server-controlled redirect enforcement
