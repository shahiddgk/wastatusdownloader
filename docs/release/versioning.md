# WA Status Downloader versioning

**Product:** WA Status Downloader  
**Package:** `ratedwhats.appstatusdownloader`

`pubspec.yaml` is the version source of truth:

```yaml
version: MAJOR.MINOR.PATCH+BUILD
```

Flutter maps `MAJOR.MINOR.PATCH` to Android `versionName` and iOS `CFBundleShortVersionString`. It maps `BUILD` to Android `versionCode` and iOS `CFBundleVersion`.

## Release calculation

The release tool examines Conventional Commits since the latest release tag:

- `fix:` selects a patch increase.
- `feat:` selects a minor increase.
- `!:` or `BREAKING CHANGE:` selects a major increase.
- documentation, test, CI, and ordinary chore commits do not select a release.

A maintainer starts the GitHub Actions workflow manually and sets `publish_release: true`. Ordinary pushes and pull requests never update the version or create a tag.

The manual workflow can choose `auto`, `patch`, `minor`, or `major`. It updates `pubspec.yaml` when required, creates the annotated tag, then builds and publishes signed artifacts. A dry run calculates the proposed version without committing, tagging, or publishing.

Every distributed build must use a build number greater than every previously distributed build.
