# Release checklist

**Product:** WA Status Downloader  
**Android package:** `ratedwhats.appstatusdownloader`  
**iOS bundle ID:** `ratedwhats.appstatusdownloader`

## Source and quality

- [ ] `git status` contains only intended changes.
- [ ] No keystore, `key.properties`, certificate, password, token, or user media is tracked.
- [ ] `dart format --output=none --set-exit-if-changed lib test integration_test tool` passes.
- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes.
- [ ] `./gradlew :app:testDebugUnitTest` passes from `android/`.
- [ ] Version and build number in `pubspec.yaml` are correct.

## Signed Android release

- [ ] Application ID and namespace are `ratedwhats.appstatusdownloader`.
- [ ] App label is **WA Status Downloader** and launcher label is **WA Status Downloader**.
- [ ] Minimum Android version is Android 10 / API 29.
- [ ] `android.permission.INTERNET` is absent.
- [ ] `MANAGE_EXTERNAL_STORAGE`, legacy read/write external-storage permissions, and broad media-library permissions are absent from the final APK/AAB manifest.
- [ ] The upload keystore and both passwords have an encrypted backup.
- [ ] `flutter build apk --release` succeeds.
- [ ] `flutter build appbundle --release` succeeds.
- [ ] `apksigner verify --verbose --print-certs` succeeds for the APK.
- [ ] APK package, version, label, and permissions are checked with `aapt dump badging`.
- [ ] A fresh install is tested on a physical Android device: **Connect WhatsApp Media** opens Android's picker toward WhatsApp Media; tapping **Use this folder**, then **Allow** permits discovery.
- [ ] The physical-device test confirms the persisted connection survives an app restart and shows a useful reconnect path after Android access is revoked.
- [ ] SHA-256 checksums accompany public downloads.

## Google Play gate

- [ ] The final uploaded AAB has the scoped folder-access manifest described above; no All files access declaration is submitted.
- [ ] Google Play App Signing is configured.
- [ ] Required support and privacy-policy URLs are published.
- [ ] Data Safety and permission declarations match the tested binary.
- [ ] Store copy and screenshots describe only implemented behavior.

## iOS gate

- [ ] Display name is **WA Status Downloader**.
- [ ] A matching Apple Distribution certificate and provisioning profile are configured.
- [ ] The product scope does not claim WhatsApp status discovery.
- [ ] A verified iOS media-import flow exists before public release.
- [ ] App Privacy declarations match the tested binary.
