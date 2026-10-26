# App identity, launcher artwork, and status labels

The application ID and Kotlin namespace are `ratedwhats.appstatusdownloader`.
The iOS bundle ID uses the same value. The Android launcher activity, Android
application information, and iOS home-screen label all use
**WA Status Downloader**.

Changing the Android application ID creates a separate installed application.
An installation of `offline.wastatus.downloader` is not upgraded or removed.
Its private preferences and permission grants do not transfer automatically.
Existing publicly saved media remains discoverable after granting access.
The internal scanner method-channel name is
`ratedwhats.appstatusdownloader/scanner` on both Dart and Android.

The launcher uses the text-free raster master in `assets/icon/launcher_icon.png`.
Android adaptive icons inset it by 12% to keep the symbol clear of launcher
masks. Legacy Android densities and iOS icon sizes derive from that master.
See [launcher asset notes](../../assets/icon/launcher-icon.md) for the generation
prompt and packaging details.

## Name and number labels

The current native scanner returns file metadata, not an association between a
status file and a WhatsApp contact. Do not infer a sender from a filename, media
content, or an opaque status ID. The app does not read WhatsApp's private database
or request contacts, notifications, or accessibility access for this feature.

Each photo or video in WhatsApp and WhatsApp Business has an **Add name / number**
action. This opens an editor that explicitly describes the label as user-entered.
Labels can be edited or removed and also appear in the full-screen viewer.
Automatic identification of the sender is not implemented.

`StatusLabelRepository` stores only the entered label in app preferences through
the existing `shared_preferences` dependency, keyed by the opaque status ID.
It creates no media copies and sends no data to a service. Identical filenames
from different sources have distinct native IDs and therefore separate labels.
Labels belong to individual discovered files, not contacts or all of a person's
statuses. A separately saved copy has a different ID and does not inherit a label.
Labels survive app restarts and permission changes, until explicitly removed or
app data is deleted. They are not pruned just because a temporary scan is empty.

The application controller handles persistence and exposes loading/read errors.
The editor retains the previous label if writing fails and offers a retry. UI
widgets do not directly access preferences or platform channels.

## Platform references

- [Android application IDs and namespaces](https://developer.android.com/build/configure-app-module)
- [Adaptive icon safe area](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive)
- [Android app-specific storage](https://developer.android.com/training/data-storage/app-specific)
