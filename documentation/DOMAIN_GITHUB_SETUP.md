# qrajn.online and GitHub

## Domain
The deployment script publishes Hosting but DNS ownership must be completed in your registrar:
1. Firebase Console → Hosting → Add custom domain.
2. Enter `qrajn.online`.
3. Copy the exact TXT/A/AAAA records Firebase provides into DNS.
4. Add `www.qrajn.online` and redirect it to the apex domain.
5. Wait for DNS propagation and managed SSL.

## GitHub
Install and authenticate GitHub CLI:
`gh auth login`

Then run:
`./04_PUSH_GITHUB.ps1 -Repository "OWNER/QR-AJN"`

The script excludes upload keys, Firebase generated private build configuration, Play output and production configuration.
