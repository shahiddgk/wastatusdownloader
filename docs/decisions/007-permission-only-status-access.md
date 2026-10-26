# ADR 007: Permission-only access for direct APK installation

## Status

Superseded by [ADR 008: Play-compliant scoped WhatsApp Media access](008-play-store-scoped-status-access.md).

## Historical record

This decision documented a direct-install-only build that used Android All files access to avoid a folder-selection step. Google Play rejected that access model for this app because broad file access is not a permitted core feature here.

The current Android release does not request All files access or legacy external-storage permissions. It uses the user-confirmed, persisted scoped folder access described in ADR 008 and the implementation details in [ADR 001](001-saf-media-discovery.md).
