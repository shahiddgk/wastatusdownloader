# GitHub releases

WA Status Downloader releases are manually initiated from the GitHub Actions **Run workflow** screen.

## Publish flow

1. Select `publish_release: true`.
2. Choose `auto`, `patch`, `minor`, or `major`.
3. Optionally select `dry_run` to calculate without tagging or publishing.
4. The workflow verifies Android signing secrets.
5. It updates `pubspec.yaml` when needed, creates an annotated tag, builds signed Android artifacts, and validates the APK.
6. It publishes APK, AAB, optional IPA, and `SHA256SUMS.txt` to a GitHub Release.

Pushes and pull requests perform validation and build a debug APK. They do not publish releases.

## Required Android secrets

- `ANDROID_UPLOAD_KEYSTORE_BASE64`
- `ANDROID_UPLOAD_STORE_PASSWORD`
- `ANDROID_UPLOAD_KEY_PASSWORD`

The uploaded keystore must contain alias `upload`.

## Artifact names

- `WA-Status-Downloader-vX.Y.Z-Android.apk`
- `WA-Status-Downloader-vX.Y.Z-Android.aab`
- `WA-Status-Downloader-vX.Y.Z-iOS.ipa` when configured
- `SHA256SUMS.txt`
