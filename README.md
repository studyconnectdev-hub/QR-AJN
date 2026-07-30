# QR AJN Complete Production V5.0.0

QR AJN is a private QR scanner, professional QR creator and digital business identity platform.

## Main products

1. **QR AJN Android app**
   - No compulsory login for scanning or ordinary static QR creation.
   - Bottom navigation: Home, Scanner and Generator.
   - Home contains only Scan QR and Create QR.
   - Intelligent scanner with auto zoom, tap focus, gallery scan, multi-target selection and safe result handling.
   - Thirty professional QR categories with dedicated data flows.
   - Gradient QR designer, logo, pattern, error correction, scan-quality score, PNG, SVG and PDF export.
   - Optional Firebase business account, dynamic QR manager, business analytics, ads and premium plans.

2. **qrajn.online**
   - Public digital business profiles.
   - Step-by-step profile builder.
   - Google and Email/Password authentication.
   - Dynamic QR destination manager.
   - Privacy-safe analytics dashboard.
   - vCard contact download, call, WhatsApp, email, directions, UPI, reviews, booking, products, services, gallery, brochure, branches, languages, testimonials, certifications and offers.

3. **Optional Blaze backend**
   - Secure dynamic redirects.
   - Expiry and scan limits.
   - Device-aware routing.
   - SSRF/private-network protection.
   - Privacy-minimized analytics.
   - Google Play subscription verification.
   - Cloud Run deployment.

## Android production configuration

- Package: `com.qr.ajn`
- Version: `5.0.0+50`
- compileSdk: 36
- targetSdk: 36
- minSdk: 24
- Android Gradle Plugin: 8.10.1
- Gradle: 8.11.1
- Kotlin: 2.3.0
- JVM target: 17 through `compilerOptions`

## One-command setup

Download the ZIP and `START_QR_AJN_V5_FULL_SETUP.ps1` to Downloads, then run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force; & "$env:USERPROFILE\Downloads\START_QR_AJN_V5_FULL_SETUP.ps1"
```

The setup asks for:

- Firebase Project ID.
- GitHub repository URL.
- Domain.
- Optional real AdMob IDs.
- Optional signed-AAB build.
- Optional Blaze backend deployment after billing is enabled.

It then:

- Checks prerequisites.
- Rebuilds the Android Gradle wrapper and production configuration.
- Connects Firebase Android and Web apps.
- Deploys Firestore, Storage, Remote Config and Hosting.
- Generates custom-domain instructions.
- Configures ads and four premium subscription IDs.
- Pushes protected source to an empty, starter-only or existing related GitHub repository.
- Builds, installs and opens the Android app.
- Optionally builds the signed AAB after the upload key is confirmed.

## Important production boundaries

Some account-owner actions cannot be safely automated:

- Enabling Google and Email/Password providers.
- Registering Play Integrity App Check.
- Entering registrar-specific DNS records shown by Firebase Hosting.
- Creating and activating Play Console subscription base plans.
- Creating real AdMob units and completing consent/Data Safety declarations.
- Using the original upload key for an existing Play listing.
- Enabling Blaze billing before Cloud Run deployment.

The package creates exact instruction files for these actions instead of guessing account-specific values.


## Validation boundary

The archive is statically validated for JavaScript, JSON, XML, YAML, source markers, private-file exclusion and backend tests. The Windows launcher performs the authoritative Flutter analyzer, tests, Android Gradle build, phone installation, Firebase deployment and AAB signing on the developer computer because those steps require the local Android SDK, accounts and private signing key.
