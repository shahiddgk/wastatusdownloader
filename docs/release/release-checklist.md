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

## Signed Android direct release

- [ ] Application ID and namespace are `ratedwhats.appstatusdownloader`.
- [ ] App label is **WA Status Downloader** and launcher label is **WA Saver**.
- [ ] `android.permission.INTERNET` is absent.
- [ ] `android.permission.MANAGE_EXTERNAL_STORAGE` is present for the current direct-install flow.
- [ ] The upload keystore and both passwords have an encrypted backup.
- [ ] `flutter build apk --release` succeeds.
- [ ] `flutter build appbundle --release` succeeds when an AAB is needed.
- [ ] `apksigner verify --verbose --print-certs` succeeds for the APK.
- [ ] APK package, version, label, and permissions are checked with `aapt dump badging`.
- [ ] The signed APK is installed and tested on a physical Android device.
- [ ] SHA-256 checksums accompany public downloads.

## Google Play gate

- [ ] The All files access declaration is approved for an eligible core use case, or the permission has been removed through an approved storage redesign.
- [ ] Google Play App Signing is configured.
- [ ] Required support and privacy-policy URLs are published.
- [ ] Data Safety and permission declarations match the tested binary.
- [ ] Store copy and screenshots describe only implemented behavior.

## iOS gate

- [ ] Display name is **WA Saver**.
- [ ] A matching Apple Distribution certificate and provisioning profile are configured.
- [ ] The product scope does not claim WhatsApp status discovery.
- [ ] A verified iOS media-import flow exists before public release.
- [ ] App Privacy declarations match the tested binary.
