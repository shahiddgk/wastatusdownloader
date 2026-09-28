# Contributing to WA Status Downloader

WA Status Downloader is an Android-first Flutter application. Keep changes focused, local-first, and compatible with its layered architecture.

## Setup

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Use JDK 17 or newer for Android builds. Test storage changes on a real Android device when possible.

## Engineering rules

- Keep platform storage and MediaStore work in the Kotlin platform layer.
- Keep Flutter widgets focused on rendering state and forwarding user actions.
- Add dependencies only when the SDK cannot provide the needed behavior.
- Do not commit keystores, signing properties, API keys, tokens, user media, or generated build output.
- Add meaningful tests for business logic, state changes, and important UI behavior.
- Run `dart format` on changed Dart files.

## Commits

Use focused Conventional Commit messages such as:

```text
feat: add status filter
fix: handle revoked storage access
test: cover saved media sorting
docs: update Android storage notes
```

GitHub releases are started manually through the release workflow. Ordinary pushes and pull requests run validation and produce a debug APK only.

## License

Contributions are provided under the repository's [Apache License 2.0](LICENSE).
