# 007: Permission-only access for direct APK installation

The user requested automatic discovery of viewed statuses without selecting a folder, and a simpler interface. This supersedes decision 001 for the current direct-install build.

On Android 11+, the app declares `MANAGE_EXTERNAL_STORAGE` and opens the app-specific Android access setting only after the user taps **Allow access**. Returning from settings checks the actual grant; cancelling does not mark access granted. Android 10 and earlier use runtime read/write storage permission, with the Android 10 legacy storage flag. Permanently denied legacy permission opens app settings on the next user request. Foreground resume rechecks access.

The Android 11+ user flow is **Allow access → enable the All files access switch → Back**. Status discovery starts automatically after the app verifies the grant; there is no folder selection. This special permission cannot be replaced with an ordinary runtime permission dialog. The APK must actually declare `MANAGE_EXTERNAL_STORAGE`: removing it from the manifest leaves the system switch disabled even when the app opens the correct settings page. Manifest changes require rebuilding and updating the installed APK, not hot reload. Legacy read/write permissions are limited to API 29 and below. Native manifest regression tests protect these declarations, and device verification must exercise the system switch rather than relying only on an ADB pre-grant.

Android's [all-files access documentation](https://developer.android.com/training/data-storage/manage-all-files) explicitly includes `Android/media` in shared storage. This is a broad OS grant, although the app only scans known WhatsApp status directories and its own saved albums. No account, network service, or media upload is added.

Google Play [restricts this permission](https://support.google.com/googleplay/android-developer/answer/10467955). This implementation is for direct APK installation and is not a claim of Play eligibility. A future Play release must restore a scoped folder grant or adopt another eligible access strategy.

`StatusFileCatalog` centralizes modern and legacy directory candidates for WhatsApp and WhatsApp Business. Mounted volumes come from Android. A missing directory produces an empty list; unreadable existing directories fail rather than reporting success. Only nonempty supported media files are listed; sentinel, partial and unrelated chat files are excluded. Native media operations use registered opaque identifiers.

Saved reads `Pictures/SavedStatus` and `Movies/SavedStatus` independently of current statuses. All new saves use those gallery albums; previous custom destination preferences are no longer used. Existing files in custom destinations are not moved or deleted and remain available there.

Status and Saved show source/filter controls and media. Settings contains access status and working theme choices. Inactive switches, artificial progress, duplicate headings and unsupported encryption claims are removed.

Verification covers native catalog cases, permission source races, concise UI actions, saved-library independence and Android emulator media operations. Physical WhatsApp behavior and older Android versions still require device-specific testing.
