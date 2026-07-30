# QR AJN V4 — Validation Report

Generated: 2026-07-30T11:24:41

Files validated: 141

- **PASS** — JSON parsing: 8 files
- **PASS** — YAML parsing: 3 files
- **PASS** — Android XML parsing: 12 files
- **PASS** — Android package: com.qr.ajn
- **PASS** — Android SDK: 36
- **PASS** — Android Gradle Plugin: 8.10.1
- **PASS** — Gradle wrapper: 8.11.1
- **PASS** — Version: 4.0.0+40
- **PASS** — Dependency mobile_scanner: ^7.4.0
- **PASS** — Dependency firebase_core: ^4.12.1
- **PASS** — Dependency firebase_auth: ^6.5.6
- **PASS** — Dependency cloud_firestore: ^6.7.1
- **PASS** — Dependency google_mobile_ads: ^9.0.0
- **PASS** — Dependency in_app_purchase: ^3.3.0
- **PASS** — Dependency pdf: ^3.11.3
- **PASS** — Dependency qr_flutter: ^4.1.0
- **PASS** — Generator categories: 30
- **PASS** — Home only primary actions
- **PASS** — Scanner auto zoom
- **PASS** — Scanner manual zoom
- **PASS** — Scanner tap focus
- **PASS** — Scanner gallery
- **PASS** — Scanner multi-code selection
- **PASS** — No PDF scanner or batch mode
- **PASS** — Firebase publishing entitlement
- **PASS** — Website profile/dynamic/premium routes
- **PASS** — Account deletion
- **PASS** — Dart relative imports: 36 files
- **PASS** — JavaScript syntax: 6 files
- **PASS** — Backend security tests: 2/2
- **PASS** — PowerShell encoding/here-strings: 11 scripts
- **PASS** — Setup file 00_CHECK_PREREQUISITES.ps1
- **PASS** — Setup file 01_CONNECT_FIREBASE.ps1
- **PASS** — Setup file 02_CONFIGURE_ADS_PREMIUM.ps1
- **PASS** — Setup file 03_DEPLOY_WEBSITE_DOMAIN.ps1
- **PASS** — Setup file 04_PUSH_GITHUB.ps1
- **PASS** — Setup file 05_BUILD_SIGNED_AAB.ps1
- **PASS** — Setup file ONE_CLICK_FULL_SETUP.ps1
- **PASS** — Setup file FULL_ONE_COMMAND.txt
- **PASS** — Asset play_store_assets/app_icon_512.png: 512x512
- **PASS** — Asset play_store_assets/feature_graphic_1024x500.png: 1024x500
- **PASS** — No embedded private credentials
- **PASS** — No stale package/version references

## Compilation boundary
Flutter and the Android SDK are not installed in this artifact environment. The included Windows scripts perform `flutter analyze`, `flutter test`, FlutterFire configuration, signed AAB generation and device/build validation on the target computer.

Node.js syntax checks and backend security tests were executed here and passed.
