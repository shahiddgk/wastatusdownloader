# Security Policy

## Supported versions

The `main` branch and the latest published release receive security fixes.

## Security and privacy model

WA Status Downloader processes status media locally.

- The Android manifest does not declare `android.permission.INTERNET`.
- The app includes no advertising, analytics, or remote crash reporting SDK.
- The direct-install Android build requests `MANAGE_EXTERNAL_STORAGE` on Android 11 and newer. The scanner limits its own work to known WhatsApp status locations and the app's saved-media locations.
- Android 10 and older supported versions use scoped legacy read and write permissions.
- Saved media is written through MediaStore.
- Platform paths stay inside the native Android layer; Flutter receives opaque media identifiers.
- Original status files are not deleted or modified.

Android's All files access grant is broad at the operating-system level. Users can revoke it from Android App Info at any time.

## Reporting a vulnerability

Report security issues privately through the repository's GitHub Security Advisory page or the maintainer contact listed in the repository profile. Include affected versions, reproduction steps, and impact. Do not include private user media in the report.
