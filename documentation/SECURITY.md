# Security model

## Spark mobile release

- Raw QR values are kept in memory only.
- Unknown HTTPS domains are never labelled Trusted; Trusted requires an exact directory match.
- UPI codes are parsed locally and require explicit confirmation in the payment app.
- Analytics is disabled by default and contains category-only events when enabled for a session.
- Notifications are opt-in.
- Community reports contain a SHA-256 domain hash, reason and server timestamp, with a three-report client session limit.
- Firestore permits public configuration reads and schema-restricted report creation only.
- App Check should be enforced in the Firebase console after Play Integrity testing.

## Blaze backend

- Management routes require `x-admin-key` and use constant-time comparison.
- Dynamic destinations allow HTTP/HTTPS only and block private, loopback, link-local, documentation and multicast address ranges.
- Redirect expansion pins each request to a previously validated DNS result.
- Dynamic redirects enforce active status, expiry and maximum scan count transactionally.
- Scan IP addresses are not stored directly; a daily salted hash is recorded.
- Basic in-memory rate limiting and security headers are included.

## Required hardening for enterprise use

Replace the administrator key with verified identity tokens or IAP, store secrets in Secret Manager, enable Cloud Armor, define retention/deletion jobs, review threat-intelligence contracts, conduct penetration testing, and add formal audit export/alerting.
