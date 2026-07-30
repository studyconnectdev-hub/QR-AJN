# Architecture

## Spark runtime

Flutter performs scanning, parsing, UPI inspection, QR creation, quality estimation and risk scoring locally. Firebase Spark provides optional public configuration, Remote Config flags, sanitized reports, notifications, crash reporting, performance monitoring and category-only analytics.

## Privacy boundary

Raw scan values are never written to Firestore, Analytics, Crashlytics custom keys or logs by application code. A community report hashes only the normalized host using SHA-256.

## Upgrade boundary

The optional Blaze service is separate. The Flutter app reads `blaze_api_base_url` from Remote Config only when an administrator deploys that backend. Spark users keep all client features without that service.
