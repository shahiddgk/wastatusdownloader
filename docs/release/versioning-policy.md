# Versioning policy

WA Status Downloader uses `MAJOR.MINOR.PATCH+BUILD` in `pubspec.yaml`.

- **MAJOR** changes for incompatible product or storage migrations.
- **MINOR** changes for backward-compatible user features.
- **PATCH** changes for fixes.
- **BUILD** is a positive integer that increases for every distributed artifact.

The current repository baseline is:

```yaml
version: 1.0.1+2
```

Never reuse or decrease a build number after an APK, AAB, or IPA has been distributed or uploaded to a store track.
