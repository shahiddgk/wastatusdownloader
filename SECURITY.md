# Security Policy

## Supported versions

The `main` branch and the latest published release receive security fixes.

## Security and privacy model

WA Status Downloader processes status media locally.

- The Android manifest does not declare `android.permission.INTERNET`.
- The app includes no advertising, analytics, or remote crash reporting SDK.
- Android 10 (API 29) and newer are supported. The user connects WhatsApp Media once through Android's system folder picker, which is directed toward that location.
- The app persists only Android's read-only, user-selected folder grant and scans status documents through that scoped grant.
- The manifest does not request `MANAGE_EXTERNAL_STORAGE`, legacy read/write external-storage permissions, or broad media-library permissions.
- Saved media is written through MediaStore.
- Platform paths stay inside the native Android layer; Flutter receives opaque media identifiers.
- Original status files are not deleted or modified.

The user can revoke or replace the folder connection through Android at any time. If it is revoked, the app asks the user to reconnect before it can discover statuses again.

## Reporting a vulnerability

Report security issues privately through the repository's GitHub Security Advisory page or the maintainer contact listed in the repository profile. Include affected versions, reproduction steps, and impact. Do not include private user media in the report.
