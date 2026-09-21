# Package, launcher, and status-label verification

Date: 2026-09-21

## Automated checks

- `flutter analyze --no-pub`: passed, no issues.
- `flutter test`: all 230 existing tests passed.
- `flutter test --no-pub test/features/status_labels`: 8 new tests passed.
- `./gradlew :app:testDebugUnitTest`: 14 native tests passed under the new namespace.
- `flutter build apk --debug`: passed.
- `git diff --check`: passed.
- `plutil -lint` on the iOS Info.plist and Xcode project: passed. An iOS build was
  not run; iOS runtime behavior is not claimed as verified.

The new tests cover repository reopening, phone formatting, removal without
deleting unrelated preferences, saving failures and retry, adding/editing/removing
labels, read-error recovery, large-text accessibility, and photo/video labels
remaining separate when switching between WhatsApp and WhatsApp Business.

## Packaged Android identity

Inspection of `build/app/outputs/flutter-apk/app-debug.apk` with Android `aapt`
confirmed:

- Package: `ratedwhats.appstatusdownloader`
- Main activity: `ratedwhats.appstatusdownloader.MainActivity`
- Launcher label: `WA Saver`
- Application label: `WA Status Downloader`
- FileProvider authority: `ratedwhats.appstatusdownloader.fileprovider`
- Launcher resource: adaptive `ic_launcher.xml`, using the inset text-free artwork.

The native production classes differ only by their namespace/import paths.
The package regression unit test now inspects an actual compiled class instead of
comparing two hard-coded strings.

## Physical Android check

- Installed the debug APK on a connected Motorola moto g24 power, Android 14.
- Launched `ratedwhats.appstatusdownloader/.MainActivity`: Android reported
  `Status: ok` and a successful cold start.
- Visually checked the actual app's source selector, photo/video counts, and
  empty state. No user media was copied, altered, or added for this check.
- Local screenshots are in `build/qa/branding-status-labels/` (ignored build
  artifacts, not committed).
- At a later check, the new package was no longer installed on the phone;
  `pm list packages ratedwhats` returned no match. It was not reinstalled after
  this external device-state change. A launcher screenshot could not be verified.

The Pixel emulator installation also returned `Success`, but the emulator was
too slow for interactive checks on this host and was stopped after switching to
the physical device. Real-device label editing on discovered WhatsApp media was
not exercised because the connected phone's status list was empty. The
corresponding interactions and source-switching behavior are covered by widget
tests.

## Functional scope

Name/number labels are entered by the user and persisted in app preferences.
Automatic WhatsApp sender lookup is not implemented because the current scanner
has no sender metadata. The editor explicitly explains this limitation.

The application ID change creates a separate installation. Existing app-private
settings and permission grants are not migrated. Publicly saved media is untouched.
