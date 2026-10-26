# Release strategy

## Android distribution

The same signed Android release can be distributed as an APK where appropriate or uploaded as an AAB to Google Play. It supports Android 10 (API 29) and newer, omits `android.permission.INTERNET`, and uses Android's one-time scoped WhatsApp Media folder connection for status discovery.

## Google Play

The upload AAB must be built from the scoped-access configuration: no `MANAGE_EXTERNAL_STORAGE`, legacy read/write external-storage permissions, or broad media-library permissions. The listing and Data safety answers must accurately describe the one-time Android folder confirmation. This removes the All files access issue; it does not replace normal Play policy review.

If Google Play App Signing is enabled, keep the Play app-signing key managed by Google and use this repository's `upload` key only to authenticate uploads.

## iOS

The iOS bundle identifier is `ratedwhats.appstatusdownloader` and the display name is **WA Status Downloader**. App Store packaging requires a matching Apple Distribution certificate and provisioning profile.

## Versioning

The Flutter `version: X.Y.Z+N` entry supplies Android and iOS versions. Build numbers must increase for every store upload.

## Release gate

A GitHub Release is created only through a manual workflow dispatch with `publish_release: true`, successful tests, valid upload signing, and successful artifact validation.
