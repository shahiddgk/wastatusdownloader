# Store metadata draft

**Product:** WA Status Downloader  
**Launcher name:** WA Status Downloader\
**Android package:** `ratedwhats.appstatusdownloader`

Support, marketing, privacy-policy, and publisher URLs are not configured in this repository.

## Android listing draft

**Title:** `WA Status Downloader`

**Short description:**  
`Browse and save viewed WhatsApp status photos and videos on your device.`

**Description:**

```text
WA Status Downloader helps you browse status photos and videos that are already
available on your Android device.

• Browse WhatsApp and WhatsApp Business status media
• Preview photos and play videos
• Save copies to Pictures/SavedStatus or Movies/SavedStatus
• Share media through Android's system share sheet
• Add your own local name or number label to a status
• Choose light, dark, or system appearance
• Browse and save media offline with no account, advertising, analytics, or cloud upload
• Install required updates through Google Play when an eligible newer version is detected

WA Status Downloader processes media on your device and does not request internet
access. Connect WhatsApp Media once through Android's system picker, then confirm
the selected folder to browse statuses already available on your device. The app
never identifies a status sender automatically.

Update checks and installation are handled by Google Play. Once a required update
is detected, install it to continue using the app. Google Play may process
update-related device and app metadata; the app does not send media or labels to it.

WA Status Downloader is independent and is not affiliated with, endorsed by, or
sponsored by WhatsApp or Meta.
```

## Permission disclosure

On Android 10 and newer, WA Status Downloader asks the user once to connect WhatsApp Media through Android's system folder picker. The picker is directed toward WhatsApp Media; the user confirms **Use this folder**, then **Allow**. Android persists a read-only connection for status discovery until the user revokes or changes it.

The app does not request All files access, legacy read/write external-storage permissions, or broad media-library permissions. Saved copies are created through MediaStore in the user's gallery.

## Privacy declarations

The current app has no account system, Android internet permission, advertising SDK, or analytics SDK. Media and user-entered labels stay on the device. Google Play handles update checks and installation in its own process and may process update-related metadata. Review the Google Play In-App Updates data safety disclosure when completing store declarations.

## iOS

The Flutter interface and bundle identity are maintained, but WhatsApp status discovery is unavailable on iOS because other apps' private containers are inaccessible. Do not publish an iOS listing that claims automatic status discovery until an iOS-specific import flow is implemented and verified.
