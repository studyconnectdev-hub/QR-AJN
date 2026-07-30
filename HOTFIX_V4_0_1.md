# QR AJN V4.0.1 Hotfix

Fixed:

- Forces Android Studio bundled JBR before Flutter/Gradle commands.
- Rejects Java versions newer than Gradle 8.11.1 supports.
- Prevents `java -version` stderr from terminating Windows PowerShell.
- Wraps prerequisite and Git commands with exit-code handling.
- Accepts GitHub repository values as `OWNER/REPO`, HTTPS URLs, or SSH URLs.
- Adds a self-locating one-command launcher.
- Does not include or call Vercel or UNNA Space deployment scripts.
