# QR AJN V5 Production Architecture

## Spark layer

- Firebase Authentication
- Cloud Firestore
- Cloud Storage
- Firebase Hosting
- Remote Config
- App Check
- Crashlytics
- Performance Monitoring
- FCM
- Android app and static web profile application

## Optional Blaze layer

- Cloud Run redirect and billing API
- Android Publisher API
- Privacy-safe analytics aggregation
- Dynamic routing, expiry and scan limits
- Lead processing
- Scheduled jobs, webhooks and advanced reports

## Security model

- Static scanning remains local and account-free.
- Raw scan payloads are not stored as history.
- Public profile reads require `published == true`.
- Profile and dynamic QR writes require ownership.
- Public publishing and dynamic QR writes require server entitlements.
- Storage writes are limited to the signed-in owner, content type and file size.
- Redirect backend blocks private networks and unsafe schemes.
- Signing keys, Firebase generated files and local production config are excluded from Git.
