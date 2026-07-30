# Release checklist

- [ ] Final package name selected before Firebase registration
- [ ] Permanent upload keystore created and backed up securely
- [ ] App Check Play Integrity configured and tested
- [ ] Firestore rules deployed
- [ ] Remote Config defaults deployed
- [ ] Privacy policy placeholders replaced and hosted over HTTPS
- [ ] Data Safety form reviewed against final SDKs
- [ ] Camera permission appears only when scanning is opened
- [ ] Notification permission has clear purpose
- [ ] Test QR, URL, Wi-Fi, UPI, gallery and share-sheet flows on physical devices
- [ ] Test airplane/offline mode
- [ ] Test Android 8 through Android 16 where available
- [ ] Run `flutter analyze` and `flutter test`
- [ ] Upload AAB to Internal testing
- [ ] Review Android vitals, Crashlytics and pre-launch report
- [ ] Confirm no test ad IDs or debug App Check provider in release
