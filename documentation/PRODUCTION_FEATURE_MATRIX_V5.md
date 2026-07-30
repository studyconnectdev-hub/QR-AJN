# QR AJN V5 Production Feature Matrix

## Android mobile application

| Area | Implemented |
|---|---|
| Navigation | Home, Scanner and Generator only |
| Home | Only Scan QR and Create QR professional animated cards |
| Scanner | Automatic detection, auto zoom, tap focus, manual zoom, flash, camera switch, gallery scan, duplicate suppression, multiple-code selection and animated targeting |
| Safe actions | URL, deep links, Android intents, UPI, phone, SMS, email, WhatsApp, Telegram, Wi-Fi, contacts, maps, calendar, app stores, social links, barcodes, ISBN, text, JSON and ticket payloads |
| Payments | Payee, UPI ID, amount, currency, note and payment-app confirmation before redirect |
| Generator | 30 category cards and dedicated category-specific fields |
| QR studio | Palettes, gradients, background, transparency, pattern shapes, eyes, logo, caption, margin and error correction |
| Quality | Contrast/payload/error-correction quality score and minimum-quality guard |
| Export | PNG, share/copy, SVG Pro, PDF Pro and high-resolution generation |
| Accounts | No login for scanning/static QR; Google or Email/Password for cloud business tools |
| Business | 16 templates, public profile builder, media upload, dynamic QR and analytics |
| Ads | UMP privacy flow, banner, interstitial and rewarded ads with development test IDs |
| Premium | Pro monthly/yearly and Business monthly/yearly |
| Privacy | No automatic scan history and no raw QR payload in analytics |

## qrajn.online

| Area | Implemented |
|---|---|
| Landing page | Responsive professional product website |
| Public routes | `/@slug`, `/business/slug`, `/card/slug`, `/q/CODE` |
| Profile builder | Four-step identity, actions, content and publish flow |
| Public card | Cover, profile image, logo, contact, vCard, products, services, gallery, brochure, UPI, review, booking and social links |
| Dynamic QR | Destination, Android/iPhone/Desktop routing, fallback, active state and scan limit |
| Analytics | Owner-only business metrics dashboard |
| Authentication | Google and Email/Password |
| Storage | Images and PDF brochure upload |
| Hosting | SPA rewrites, security headers and custom-domain workflow |

## Firebase Spark-first

- Authentication
- Firestore
- Cloud Storage
- Hosting
- Remote Config and real-time updates
- App Check
- Crashlytics
- Performance Monitoring
- FCM
- Security rules and indexes

## Optional Blaze backend

- Cloud Run
- Server-side dynamic redirects
- Expiry and scan-limit enforcement
- Device-aware routing
- Privacy-minimized analytics
- Play Billing verification
- Android Publisher API
- SSRF and private-network protection
