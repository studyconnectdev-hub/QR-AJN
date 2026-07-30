# QR AJN V4 — Updated Files and Modules

Generated: 2026-07-30T11:24:03

## Mobile
- `flutter_app/lib/features/home/home_screen.dart` — Home with only Scan QR and Create QR.
- `flutter_app/lib/features/scanner/scanner_screen.dart` — fast scanning, auto/manual zoom, tap focus, gallery and multi-code selection.
- `flutter_app/lib/features/generator/` — 30 categories, dedicated detail screens, customization, preview, quality scoring and PNG/SVG/PDF export.
- `flutter_app/lib/features/business/` — optional Firebase account and qrajn.online profile builder.
- `flutter_app/lib/features/premium/` — Play Billing plans and restore.
- `flutter_app/lib/core/services/ad_service.dart` — UMP consent, banner/interstitial/rewarded ads.
- `flutter_app/lib/core/services/premium_service.dart` — provisional purchase window, secure verification, restore and entitlement revocation.
- `flutter_app/lib/core/services/firebase_bootstrap.dart` — Firebase/App Check/Remote Config/Crashlytics/Performance/FCM.
- Android package fixed to `com.qr.ajn`, SDK 36, AGP 8.10.1 and Gradle 8.11.1.

## Firebase
- Firestore rules and indexes.
- Publishing entitlement checks for public business profiles.
- Remote Config template.
- Firebase Hosting configuration and security headers.
- Optional analytics and community safety rules.

## qrajn.online
- Landing page.
- Email/password and Google sign-in.
- Business profile builder and private draft mode.
- Public profile pages.
- Editable dynamic-link records.
- Save-contact actions.
- Privacy and account-deletion pages.

## Monetization
- Google Mobile Ads with test IDs by default and production-ID injection.
- Google Play Billing products:
  - `qrajn_pro_monthly`
  - `qrajn_pro_yearly`
  - `qrajn_business_monthly`
- Optional Cloud Run Google Play purchase verification.

## Automation
- Prerequisite checks and CLI installation.
- FlutterFire/Firebase setup.
- Ads and premium configuration.
- Firebase Hosting and domain guide.
- GitHub repository creation/push.
- Permanent upload-key creation.
- Signed AAB build and signature/checksum output.
