# Store metadata draft

**Product:** WA Status Downloader  
**Launcher name:** WA Saver  
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
• Work offline with no account, advertising, analytics, or cloud upload

WA Status Downloader processes media on your device and does not request internet
access. The app never identifies a status sender automatically.

WA Status Downloader is independent and is not affiliated with, endorsed by, or
sponsored by WhatsApp or Meta.
```

## Permission disclosure

The current direct-install build asks the user to enable Android **All files access** on Android 11 and newer. The operating-system grant is broad. The application scanner limits itself to known WhatsApp status folders and its saved-media locations.

Google Play restricts this permission. Do not submit this build to Google Play until the declaration is approved for an eligible core use case or the app adopts another storage strategy.

## Privacy declarations

The current app has no account system, network permission, advertising SDK, analytics SDK, or remote service. Media and user-entered labels stay on the device.

## iOS

The Flutter interface and bundle identity are maintained, but WhatsApp status discovery is unavailable on iOS because other apps' private containers are inaccessible. Do not publish an iOS listing that claims automatic status discovery until an iOS-specific import flow is implemented and verified.
