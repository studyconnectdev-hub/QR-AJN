# QR AJN Play Console Data Safety Working Guide

Review these answers against the exact production binary, Firebase/AdMob settings and Google Play definitions before submission.

## Data QR AJN does not intentionally store as scan history
- Raw scanned QR or barcode values
- UPI PINs
- Wi-Fi passwords
- Contact-card contents
- Generated QR history
- Precise GPS location from the scanner

## Optional account and business-profile data
When the user chooses cloud business features, QR AJN may collect email/authentication identifiers, public business-profile content, products/services/contact links, and premium entitlement/purchase identifiers.

## Firebase diagnostics and configuration
Depending on enabled services, Firebase may process crash logs, diagnostics, device/app identifiers, performance data, optional Analytics events, notification tokens after opt-in and App Check integrity signals.

## Advertising
The free plan includes Google Mobile Ads when production IDs are configured. Disclosures may include device/ad identifiers, approximate location, ad interactions and diagnostics depending on consent, region and Google SDK behavior.

## Purchases
Google Play Billing processes payment information. QR AJN receives product ID, purchase ID/token and verification data, but not the user's full payment-card details.

## Deletion
Local scan data is not maintained as account history. Users can unpublish/delete business profiles. Add and test the in-app account-deletion workflow before enabling public registration in production.
