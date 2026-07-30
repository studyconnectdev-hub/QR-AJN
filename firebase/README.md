# Firebase Spark resources

Deploy rules and Remote Config with `DEPLOY_FIREBASE.ps1`.

The app always ships bundled rule files, so Firestore seed documents are optional. To enable live rules, create these documents in Firestore:

- `public_config/security_rules`
- `public_config/trusted_domains`

Use the fields shown in `seed_documents.example.json`.

Enable App Check enforcement only after confirming Play Integrity tokens work in Internal testing. Enforce App Check for Firestore after that validation.
