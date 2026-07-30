# Firebase, AdMob and Premium Setup

## Firebase
1. Create a Firebase project.
2. Add Android app package `com.qr.ajn`.
3. Run `01_CONNECT_FIREBASE.ps1`.
4. Enable Email/Password and Google providers.
5. Register the release SHA-256 in Firebase App Check / Play Integrity.
6. Deploy Firestore rules, indexes, Remote Config and Hosting.

## AdMob
1. Create Android app `com.qr.ajn` in AdMob.
2. Create Banner, Interstitial and Rewarded units.
3. Run `02_CONFIGURE_ADS_PREMIUM.ps1` with the real IDs.
4. Complete AdMob privacy messaging/consent configuration for the countries you serve.
5. Do not click your own live ads.

## Google Play Billing
Create:
- `qrajn_pro_monthly`
- `qrajn_pro_yearly`
- `qrajn_business_monthly`

Add base plans and regional prices, activate the products and add license testers. The app can restore purchases and queues receipt verification. Deploy the Blaze backend for secure server verification.

## Blaze verification
Grant the Cloud Run service account access in Play Console API access, enable Android Publisher API, deploy `blaze_backend`, and set `blaze_api_base_url` in Remote Config.
