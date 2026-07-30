# QR AJN V4 — Manual Console Actions

The source and automation scripts are complete, but these account-owner actions cannot be performed safely without your credentials.

## Firebase
1. Create a Firebase project.
2. Run `ONE_CLICK_FULL_SETUP.ps1` with the project ID.
3. Enable Email/Password and Google Authentication.
4. Register Android App Check with Play Integrity.
5. Add the release SHA-256 certificate after the upload key is created.
6. Review Firestore and Remote Config after deployment.

## qrajn.online
1. Open Firebase Hosting and add `qrajn.online`.
2. Copy the exact TXT/A/AAAA records shown by Firebase into your domain registrar.
3. Add `www.qrajn.online` and redirect it to the root domain.
4. Wait for DNS propagation and Firebase managed SSL.

## AdMob
1. Create the Android app with package `com.qr.ajn`.
2. Create Banner, Interstitial and Rewarded ad units.
3. Rerun setup with the real IDs.
4. Keep Google test IDs during development and internal testing.
5. Complete UMP/privacy and Play Console Ads declarations.

## Google Play Billing
1. Upload an internal-test AAB.
2. Create and activate:
   - `qrajn_pro_monthly`
   - `qrajn_pro_yearly`
   - `qrajn_business_monthly`
3. Add base plans, regional prices and license testers.
4. For secure cross-device verification, deploy the optional Blaze backend and grant its service account Google Play Android Developer API access.

## GitHub
1. Sign in with GitHub CLI when prompted.
2. Provide `OWNER/REPOSITORY` to the one-click script.
3. Private signing/Firebase files are excluded by `.gitignore`.

## Signing
1. The build script creates a permanent upload keystore only if none exists.
2. Back up the generated `.jks` and `UPLOAD_KEY_RECOVERY_PRIVATE.txt` permanently.
3. Never create a different upload key for future updates.
