# WA Status Downloader privacy and data practices

## Data processing

WA Status Downloader discovers, previews, labels, shares, and saves media on the user's device. It does not declare Android internet access and contains no advertising or analytics SDK.

The app does not upload media, filenames, labels, usage events, or device identifiers.

## Android storage access

The current direct-install build requests Android All files access on Android 11 and newer. This is a broad operating-system grant. Application code limits discovery to known WhatsApp and WhatsApp Business status locations plus the app's saved-media folders.

On older supported Android versions, the app requests the legacy storage permissions needed for the same functions. Users can revoke access from Android App Info.

## Local data

- Thumbnail and playback files may be written to the application cache.
- Saved photos are written through MediaStore to `Pictures/SavedStatus`.
- Saved videos are written through MediaStore to `Movies/SavedStatus`.
- User-entered name or number labels and preferences are stored locally.
- Clearing app storage removes app-private preferences and caches. Publicly saved media remains until the user deletes it.

## Store declarations

Google Play restricts `MANAGE_EXTERNAL_STORAGE`. Publishing this build on Google Play requires an eligible core use case and an approved permission declaration, or a storage implementation that avoids the permission.

No data is collected or shared through a remote service by the current application.
