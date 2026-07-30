# Feature matrix

| Feature | Spark/free app | Blaze backend source |
|---|---:|---:|
| Camera, gallery, screenshot and shared-image scanning | Implemented | Not required |
| Clean single-result scanner with pause/resume | Implemented | Not required |
| Smart parser and local SafeScan | Implemented | Optional network inspection |
| UPI preview, app selection and explicit confirmation | Implemented | Not required |
| 26 static QR generator categories | Implemented | Not required |
| Color palettes, shapes, logo, captions and PNG export | Implemented | Not required |
| Six clickable Home feature hubs and sub-screens | Implemented | Live status from Spark rules |
| Downloadable threat rules | Remote Config + optional Firestore | Not required |
| Exact-match trusted-business directory | Implemented | Optional moderation |
| Sanitized community reports | Firestore create-only rules | Optional moderation pipeline |
| Category-only Analytics | Opt-in per session | Aggregate event source |
| Crashlytics, Performance, App Check and FCM | Implemented; FCM opt-in | Not required |
| Static dashboard and hosted privacy page | Firebase Hosting | Calls backend when configured |
| Dynamic editable QR with expiry/scan limits | Dashboard shell only | Implemented API and redirect |
| Secure redirect-chain expansion | Not exposed in free scanner | DNS-pinned API source |
| Inventory and attendance | No persistent Spark workflow | Event APIs implemented |
| One-time tickets | No persistent Spark workflow | Transactional API implemented |
| Product anti-counterfeit | No persistent Spark workflow | Verification API implemented |
| Premium entitlements | No billing in free app | Entitlement lookup source |
