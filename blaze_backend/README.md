# Optional Blaze backend

This Node.js 20 service implements:

- Dynamic redirects with active, expiry and maximum-scan controls.
- Transactional scan-count enforcement.
- DNS-pinned redirect-chain expansion and private-network/SSRF blocking.
- Privacy-minimized scan events using a daily salted IP hash.
- Administrator API-key protection with constant-time comparison.
- Basic per-instance rate limiting, CORS and security headers.
- Aggregate dashboard metrics.
- Inventory and attendance event ingestion.
- Transactional one-time ticket redemption.
- Serialized product verification and hashed verification events.
- Google Play subscription verification and entitlement writes.
- Subscription entitlement lookup.
- OpenAPI specification.

It requires Blaze because Cloud Run deployment is not available on Firebase Spark.

## Local validation

```powershell
npm install
npm run check
npm test
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\service-account.json"
$env:ADMIN_API_KEY="use-a-long-random-secret"
npm start
```

## Deployment

From the package root:

```powershell
.\DEPLOY_BLAZE_BACKEND.ps1 -GoogleCloudProjectId "PROJECT_ID" -AdminApiKey "LONG_RANDOM_SECRET" -AllowedOrigin "https://PROJECT_ID.web.app"
```

For a higher-risk enterprise rollout, add Identity Platform/IAP or verified Firebase ID tokens, Cloud Armor, Secret Manager, App Check verification for mobile calls, formal JSON schema validation, retention jobs, audit log exports, a reviewed threat-intelligence provider, and Play Billing webhook verification.
