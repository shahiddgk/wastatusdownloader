# WA Status Downloader

WA Status Downloader is a Flutter app for discovering, previewing, and saving viewed WhatsApp and WhatsApp Business status media on Android.

## Identity

- Product name: **WA Status Downloader**
- Launcher name: **WA Status Downloader**
- Android application ID and namespace: `ratedwhats.appstatusdownloader`
- iOS bundle identifier: `ratedwhats.appstatusdownloader`
- Android method channel: `ratedwhats.appstatusdownloader/scanner`

The launcher icon master is `assets/icon/launcher_icon.png`.

## Features

- Browse photo and video statuses from WhatsApp and WhatsApp Business.
- Preview photos and play videos in the app.
- Save media to the device through Android MediaStore.
- Share media with Android's native share sheet.
- Add a local name or number label to an individual status.
- Browse saved media in the Kept section.
- Use system, light, or dark appearance.
- Keep media processing and user-entered labels on the device.
- Require an update when Google Play reports an eligible newer version.

## Android access model

The Android app supports Android 10 (API 29) and newer. The first time status discovery is needed, Android opens its system folder picker directed toward WhatsApp Media. The user confirms the pre-opened location by tapping **Use this folder**, then **Allow**. Android keeps that read-only folder connection for later launches unless the user revokes or changes it.

The app reads only through that persisted scoped folder grant. It does not request `MANAGE_EXTERNAL_STORAGE`, legacy read/write external-storage permissions, or broad media-library permissions. Saved copies are written through MediaStore.

Google Play handles update checks and installation in its own process. The app does not declare `android.permission.INTERNET`. See [the Play storage decision](docs/decisions/008-play-store-scoped-status-access.md) and [the SAF implementation decision](docs/decisions/001-saf-media-discovery.md).

## Development

Requirements:

- Flutter 3.47.2 or a compatible stable SDK
- Dart 3.13.2 or compatible
- JDK 17 or newer for local Android builds

Run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## Release signing

A release build requires an untracked Android upload keystore and `android/key.properties`. Debug signing is never used for a release artifact.

```bash
flutter build apk --release
flutter build appbundle --release
```

See [release signing](docs/release/signing.md) and [GitHub releases](docs/release/github-releases.md).

## Architecture

The Flutter application uses layered boundaries:

```text
Presentation → Application state → Domain → Data → Platform services
```

Android storage and MediaStore operations stay behind the Kotlin platform channel. UI widgets do not access storage directly.

## Privacy

Media discovery, thumbnails, labels, playback, and saving remain on the device. The app contains no advertising or analytics SDK and requests no network permission.

## License

See [required Google Play updates](docs/release/required-updates.md) for behavior and release testing.

The source is available under the [Apache License 2.0](LICENSE). The license file retains applicable copyright attribution from the source history.

WhatsApp is a trademark of its respective owner. This project is independent and is not affiliated with or endorsed by WhatsApp or Meta.
