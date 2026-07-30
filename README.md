# QR AJN V4.0.1 Setup Hotfix

This package fixes Windows PowerShell native stderr handling, Java 25 selection, and GitHub URL normalization.

# QR AJN Complete Production V4

This package contains the Flutter Android app (`com.qr.ajn`), Firebase configuration, the `qrajn.online` business-profile website, Google Mobile Ads integration, Google Play Billing integration, optional Blaze backend, deployment scripts, GitHub scripts, Play Store documents and signed-AAB build automation.

## Implemented
- Home, Scanner and Generator bottom navigation only
- Scanner auto/manual zoom, multiple-QR selection, gallery scan and SafeScan result routing
- 30 generator categories with dedicated form, customization, preview, validation and export pages
- UPI app selection and confirmation
- Optional Firebase Authentication and business profiles
- Public `qrajn.online/@slug` profiles and editable dynamic-link records
- Remote Config, Firestore rules/indexes, App Check, Crashlytics, Performance and optional FCM/Analytics
- AdMob banner/interstitial/rewarded source with official test IDs by default
- Play Billing monthly/yearly/business products and restore/receipt queue
- Optional Cloud Run backend for secure redirects, analytics, workflows and purchase verification
- GitHub push, Firebase deployment, domain guide and signed-AAB scripts

## Required private setup
Credentials and ownership actions are intentionally not embedded:
1. Create/select Firebase project and enable Authentication providers.
2. Replace Google test ad IDs with your AdMob IDs.
3. Create Play products: `qrajn_pro_monthly`, `qrajn_pro_yearly`, `qrajn_business_monthly`.
4. Add Firebase-provided DNS records for `qrajn.online`.
5. Authenticate GitHub CLI.
6. Back up the generated Play upload keystore and recovery file.

Spark supports profiles, configuration and Hosting. Secure server-side redirects, advanced analytics and server purchase verification require Blaze/Cloud Run.

## Start
Read `FULL_ONE_COMMAND.txt`.

## Output
`PLAY_STORE_UPLOAD/QR_AJN_V4_BUILD_40_com.qr.ajn_SIGNED.aab`
