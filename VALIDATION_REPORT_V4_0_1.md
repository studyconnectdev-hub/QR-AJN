# QR AJN V4.0.1 Validation Report

Validated on 2026-07-30:

- Android Studio bundled JBR is selected before Java/Gradle checks.
- Java 25 is rejected for the included Gradle 8.11.1 toolchain; Java 17-23 is accepted.
- Windows PowerShell native stderr no longer terminates `java -version` checks.
- GitHub input accepts `OWNER/REPO`, HTTPS URLs and SSH URLs.
- Firebase CLI calls use explicit exit-code handling.
- Hosting deploy uses explicit exit-code handling.
- The package contains no Vercel or UNNA Space deployment commands.
- JSON parsing passed.
- PowerShell raw delimiter checks passed.
- JavaScript syntax checks passed.
- Blaze backend security tests passed.
- Android package remains `com.qr.ajn`.
- No Firebase credentials, signing keystore, upload-key recovery file or production secret is included.

The final Flutter/Firebase build must run on the user's Windows computer because it requires their SDKs, Firebase login, Firebase project, domain DNS access and signing key.
