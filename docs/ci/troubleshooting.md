# CI troubleshooting

## Validation failures

Run the same checks locally:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
flutter build apk --debug
(cd android && ./gradlew test)
```

## Missing release signing

A release build must have all three Android signing secrets configured. Confirm the Base64 value decodes to the intended JKS keystore, the alias is `upload`, and both passwords match.

Locally, confirm `android/key.properties` points to an existing keystore. The file and keystore are ignored by Git.

## Identity validation

The compiled APK must report package `ratedwhats.appstatusdownloader` and label `WA Status Downloader`. It must omit `android.permission.INTERNET` and include the direct-install storage permission.

## iOS packaging

If Apple secrets are absent, the workflow skips the IPA and still permits the Android GitHub Release.
