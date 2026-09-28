# Continuous integration and releases

The workflow in `.github/workflows/ci.yml` validates pushes, pull requests, and manual runs.

## Normal validation

Pushes and pull requests run:

1. tracked-secret and manifest checks;
2. application ID and license checks;
3. dependency resolution and Dart formatting;
4. Flutter analysis and tests;
5. Android JVM tests;
6. a debug APK build.

No tag or release is created from an ordinary push.

## Manual release

A maintainer starts `workflow_dispatch` and sets `publish_release: true`. The workflow calculates the next version, creates the release tag, builds signed Android APK and AAB artifacts, validates identity and permissions, produces checksums, and publishes a GitHub Release.

The Android release path requires these repository secrets:

- `ANDROID_UPLOAD_KEYSTORE_BASE64`
- `ANDROID_UPLOAD_STORE_PASSWORD`
- `ANDROID_UPLOAD_KEY_PASSWORD`

The key alias is `upload`. Optional iOS packaging also requires its Apple signing secrets.
