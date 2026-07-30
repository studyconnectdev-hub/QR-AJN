# QR AJN V5 Manual Console Actions

These actions are account-specific and intentionally not guessed by scripts.

## Firebase

1. Create a Firebase project.
2. Run the one-click setup with the Project ID.
3. Authentication:
   - Enable Email/Password.
   - Enable Google.
4. App Check:
   - Register Android package `com.qr.ajn`.
   - Select Play Integrity.
   - Add debug token only for local testing.
5. Add release SHA-1 and SHA-256 certificates after signing.
6. Activate Storage if the first deployment asks.

## qrajn.online

1. Firebase Hosting > Add custom domain.
2. Enter `qrajn.online`.
3. Add exactly the TXT/A/AAAA/CNAME records Firebase displays at the domain registrar.
4. Connect `www.qrajn.online` and redirect it to the root domain.
5. Add both domains to Firebase Authentication authorized domains.
6. Wait until Firebase shows Connected and the SSL certificate is active.

## AdMob

1. Create the QR AJN Android app in AdMob.
2. Create Banner, Interstitial and Rewarded units.
3. Rerun `02_CONFIGURE_ADS_PREMIUM.ps1` with the real IDs.
4. Complete UMP privacy messaging and Play Data Safety.
5. Never test with live ad units.

## Google Play subscriptions

Create and activate:

- `qrajn_pro_monthly`
- `qrajn_pro_yearly`
- `qrajn_business_monthly`
- `qrajn_business_yearly`

Each subscription requires at least one active base plan and regional pricing.

## Signing

For an existing Play listing, the AAB must use the existing upload key. A newly generated key will not be accepted unless Google Play completes an upload-key reset.

## Blaze backend

Upgrade Firebase billing before deploying Cloud Run. Then run `DEPLOY_BLAZE_BACKEND.ps1`, configure Android Publisher API access and set Remote Config `blaze_api_base_url`.
