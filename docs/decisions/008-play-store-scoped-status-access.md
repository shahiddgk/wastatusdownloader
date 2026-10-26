# ADR 008: Play-compliant scoped WhatsApp Media access

## Status

Accepted.

## Context

WhatsApp status media can be stored in a hidden folder that Android MediaStore does not reliably index. The earlier direct-install implementation used `MANAGE_EXTERNAL_STORAGE` to scan those files without a picker. Google Play rejected that model because All files access is not a permitted core feature for this app.

The app must support Android 10 (API 29) and newer while minimizing access to the user's private media.

## Decision

- Use `ACTION_OPEN_DOCUMENT_TREE` to request a user-selected, read-only Storage Access Framework grant.
- Direct Android's system picker toward WhatsApp Media with `EXTRA_INITIAL_URI`. This is a navigation hint; the user remains in control of the final confirmation.
- Explain the single required confirmation clearly: tap **Use this folder**, then **Allow**. Persist the returned read grant only after validating that it is a WhatsApp or WhatsApp Business media tree.
- Scan status children through `ContentResolver` and document-tree URIs. The Flutter layer receives opaque item identifiers rather than filesystem paths or content URIs.
- Support Android API 29 and newer only. Do not request `MANAGE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES`, or `READ_MEDIA_VIDEO`.
- Save copies through MediaStore in the app's gallery albums rather than using raw filesystem writes.

## Consequences

- The user performs one Android-managed confirmation on first connection. The persisted grant remains usable across app restarts until the user revokes it, replaces it, clears app data, or Android removes it.
- The app can guide the picker toward WhatsApp Media, but it cannot silently grant access or bypass the system confirmation.
- If no viewed status exists yet, the folder connection can remain saved and the app asks the user to view a status in WhatsApp before trying again.
- This removes the All files access policy issue, but the final AAB, Data safety answers, listing copy, and all other Play policies still require normal release review.

## References

- [Google Play All files access policy](https://support.google.com/googleplay/android-developer/answer/10467955)
- [Android shared-media storage guidance](https://developer.android.com/training/data-storage/shared/media)
