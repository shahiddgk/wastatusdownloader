# CI security

- Root workflow permissions are `contents: read`.
- Only manual release jobs receive `contents: write`.
- Pull-request jobs do not configure Android or Apple release credentials.
- Tracked files are checked for keystores, signing properties, certificates, and local SDK configuration.
- Third-party GitHub Actions are pinned to immutable commit SHAs.
- Android signing material is decoded into `$RUNNER_TEMP` and is never added to the repository.
- Release builds require the `upload` alias and verify the resulting APK signature.
- Ordinary CI builds a debug APK.

Required Android release secrets are `ANDROID_UPLOAD_KEYSTORE_BASE64`, `ANDROID_UPLOAD_STORE_PASSWORD`, and `ANDROID_UPLOAD_KEY_PASSWORD`.
