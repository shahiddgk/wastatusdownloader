# Release strategy

## Android direct distribution

The current Android build is suitable for signed direct distribution as an APK. It includes `MANAGE_EXTERNAL_STORAGE` for permission-only status discovery and omits `android.permission.INTERNET`.

## Google Play

An AAB can be produced with the upload key, but the current storage permission is restricted by Google Play. Store submission requires an eligible core use case and an approved All files access declaration, or a product change to another access model.

If Google Play App Signing is enabled, keep the Play app-signing key managed by Google and use this repository's `upload` key only to authenticate uploads.

## iOS

The iOS bundle identifier is `ratedwhats.appstatusdownloader` and the display name is **WA Saver**. App Store packaging requires a matching Apple Distribution certificate and provisioning profile.

## Versioning

The Flutter `version: X.Y.Z+N` entry supplies Android and iOS versions. Build numbers must increase for every store upload.

## Release gate

A GitHub Release is created only through a manual workflow dispatch with `publish_release: true`, successful tests, valid upload signing, and successful artifact validation.
