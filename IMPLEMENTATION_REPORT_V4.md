# QR AJN V4 — Implementation Report

Generated: 2026-07-30T11:21:00

## Delivered
- Flutter Android application using package `com.qr.ajn`, version `4.0.0+40`.
- Bottom navigation limited to Home, Scanner and Generator.
- Home limited to Scan QR and Create QR.
- Advanced camera scanner with ML Kit/CameraX through `mobile_scanner`, auto zoom, manual zoom, tap focus, gallery scanning and multi-code selection.
- Smart QR parsing and safety preview for URLs, app links, UPI, Wi-Fi, contacts, calls, messages, email, locations, calendar, social links, products and business profiles.
- Thirty QR generator category subpages.
- Custom QR palettes, gradients, pattern shapes, center branding, margins, error correction and quality scoring.
- PNG, SVG and PDF export, sharing and copy actions.
- Firebase Authentication, Firestore, Remote Config, App Check, Analytics opt-in, Crashlytics, Performance and FCM support.
- qrajn.online landing page, authentication, public profile pages, profile builder, private drafts, dynamic links, privacy and account-deletion pages.
- AdMob banner/interstitial/rewarded foundation with UMP consent and Google test IDs by default.
- Google Play Billing plans, restore flow, three-day provisional entitlement window, secure Blaze verification and entitlement revocation.
- Optional Cloud Run backend for secure redirects, purchase verification, analytics, inventory, attendance, tickets and product verification.
- Firebase, domain, GitHub, AdMob/premium and signed-AAB PowerShell scripts.
- Play Store listing, Data Safety guidance and visual assets.

## Important production boundaries
- Firebase credentials are generated locally by FlutterFire after you supply your project ID.
- DNS ownership records for qrajn.online must be copied from Firebase to your registrar.
- Real AdMob IDs and Play Billing products must be created in your Google accounts.
- Secure purchase verification and advanced server redirects require Blaze/Cloud Run.
- This environment does not contain Flutter/Android SDK, so final Flutter compilation and signed AAB creation are performed by `05_BUILD_SIGNED_AAB.ps1` on your Windows machine.
