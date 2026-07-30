# Firebase setup

The one-command script installs/configures Firebase tools, creates the project when allowed, creates the default Firestore database, runs FlutterFire configuration, and deploys rules/Remote Config.

After the first Internal-test build:

1. Open Firebase Console → App Check.
2. Register the Android application with Play Integrity.
3. Install the Play-delivered test build.
4. Confirm valid App Check requests.
5. Enable enforcement for Firestore.
6. Add `public_config/security_rules` and `public_config/trusted_domains` only when you need live rule updates. Bundled defaults already work.
