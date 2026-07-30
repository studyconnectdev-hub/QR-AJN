# QR AJN V5 Production Validation Report

## Result

**Static/source validation: PASSED**

- Checks passed: 92
- Checks failed: 0
- Version: `5.0.0+50`
- Android package: `com.qr.ajn`
- Domain default: `qrajn.online`

## Validated in this package

- JavaScript syntax for the website and optional Blaze backend.
- Optional Blaze backend tests: 2 passed.
- JSON, XML, YAML and HTML parsing.
- Dart lexical structure across 41 source/test files.
- PowerShell lexical structure across 14 setup scripts.
- Android production markers: SDK 36, minSdk 24, Kotlin 2.3.0 and JVM 17 compiler options.
- Thirty generator categories and sixteen business-profile templates.
- Firebase, Hosting, Storage, Remote Config, GitHub, AdMob, premium and signed-AAB workflows.
- No packaged `google-services.json`, `firebase_options.dart`, `key.properties`, JKS/keystore or previous Firebase project ID.
- Website and backend public URL validation and private-network redirect protection.

## Authoritative Windows checks performed by the launcher

The following require the developer’s Windows machine, Android SDK, connected phone, Google/Firebase/GitHub accounts and private signing key, so they were not executed inside this Linux packaging environment:

1. `flutter pub get`
2. `dart format`
3. `flutter analyze --no-fatal-infos --no-fatal-warnings`
4. `flutter test`
5. Android Gradle debug APK compilation
6. Phone installation and launch
7. Firebase project/app creation and deployment
8. GitHub authentication and push
9. Signed AAB compilation and certificate verification
10. Custom-domain DNS verification
11. Real AdMob delivery and Play Billing activation

`START_QR_AJN_V5_FULL_SETUP.ps1` runs the applicable checks and deployments on the Windows computer.

## Manual account-owner actions

- Enable Firebase Email/Password and Google authentication providers.
- Register Play Integrity in Firebase App Check.
- Add the exact DNS records displayed by Firebase Hosting.
- Create real AdMob app/ad-unit IDs and complete privacy configuration.
- Create and activate the four Google Play subscription base plans.
- Use the original upload key for an existing Play listing.
- Upgrade Firebase to Blaze before deploying the optional Cloud Run backend.
