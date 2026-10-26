# WA Status Downloader privacy and data practices

## Data processing

WA Status Downloader discovers, previews, labels, shares, and saves media on the user's device. It does not declare Android internet access and contains no advertising or analytics SDK.

The app does not upload media, filenames, labels, usage events, or device identifiers.

## Android storage access

On Android 10 (API 29) and newer, the app opens Android's system folder picker directed toward WhatsApp Media when the user chooses to connect status discovery. The user taps **Use this folder**, then **Allow**, once. Android persists a read-only grant for the selected WhatsApp Media tree so the app can find status documents on later launches.

The app does not request `MANAGE_EXTERNAL_STORAGE`, legacy read/write external-storage permissions, or broad media-library permissions. Users can revoke the selected-folder grant at any time and the app will ask them to reconnect before scanning again.

## Local data

- Thumbnail and playback files may be written to the application cache.
- Saved photos are written through MediaStore to `Pictures/SavedStatus`.
- Saved videos are written through MediaStore to `Movies/SavedStatus`.
- User-entered name or number labels and preferences are stored locally.
- Clearing app storage removes app-private preferences and caches. Publicly saved media remains until the user deletes it.

## Store declarations

The Android release uses a user-selected, persisted Storage Access Framework folder grant instead of All files access. Its store disclosure should explain the one-time WhatsApp Media connection accurately and must match the final uploaded AAB.

Media and user-entered labels are not collected or shared by this application.

## Google Play updates

Google Play checks for eligible app updates and handles their download and installation in its own process. Google Play may process device and app metadata for this purpose under Google's terms; this app does not send media or user-entered labels to Google Play. Consult [Google's In-App Updates data safety disclosure](https://developer.android.com/guide/playcore/in-app-updates#data-safety) when completing store declarations.

The required update version is stored in app-private preferences. An update becomes mandatory only after Google Play reports it as available to the current user. Once detected, the requirement remains until that version or a newer version is installed. The first check may allow offline use if no required update is known.
