# QR AJN V5 Implementation Report

## Mobile application

- Clean Home with only Scan QR and Create QR.
- Bottom navigation limited to Home, Scanner and Generator.
- Animated gradient cards, logo hero, light/dark mode and reduced-motion setting.
- Automatic scanner zoom, manual zoom, tap focus, flash, camera switch, gallery scan, duplicate suppression and multi-QR tap selection.
- Safe parsing and result actions for URL, deep link, UPI, Wi-Fi, contacts, calls, SMS, email, WhatsApp, Telegram, maps, calendar, app stores, social links, barcodes, ISBN, text, JSON, tickets and QR AJN profiles.
- UPI detail preview and confirmation before redirect.
- Thirty generator categories.
- Per-category data screens and payload builders.
- QR design palettes, two- and three-colour gradients, module shapes, centre logo, caption, margin, error correction and transparent background.
- Scan-quality score.
- PNG, SVG and PDF export.
- Firebase Auth, Firestore, Storage, Remote Config, Crashlytics, Performance, FCM and App Check integration.
- Business profile builder with sixteen profile templates and comprehensive business fields.
- Firebase Storage media upload for photos, logo, cover and brochure.
- Dynamic QR manager.
- Business analytics dashboard.
- Google and email/password sign-in.
- AdMob consent, banner, interstitial and rewarded implementation.
- Four Google Play subscription product IDs and provisional/server entitlement flow.

## Website

- Responsive landing page.
- Optional authentication.
- Four-step profile builder.
- Firebase Storage uploads.
- Public business profile pages.
- Save-contact vCard.
- Dynamic QR manager and device-aware redirect selection.
- Analytics dashboard.
- Secure hosting headers and SPA rewrites.

## Backend and infrastructure

- Firestore and Storage security rules.
- Firestore indexes.
- Remote Config template.
- Firebase Hosting deployment.
- Optional Cloud Run backend with safe redirects, expiry, scan limits, analytics and Play Billing verification.
- GitHub source protection for keys and generated Firebase files.
- Android Gradle repair using a temporary clean Flutter wrapper.
- Debug APK install/run and signed AAB workflow.

## Production hardening

- Empty and starter-only GitHub repositories are handled safely.
- Firebase Web configuration is generated locally and excluded from Git; a safe example file is included.
- Domain and AdMob build definitions are propagated from the one-click setup.
- Upload-key path resolution is normalized and private signing material is backed up outside the repository.
- Public website action URLs and dynamic destinations are restricted to safe HTTP/HTTPS values.
