# WA Status Downloader release engineering

**Product:** WA Status Downloader  
**Android launcher label:** WA Status Downloader\
**Android application ID:** `ratedwhats.appstatusdownloader`  
**License:** Apache-2.0

The Android release supports Android 10 (API 29) and newer and is prepared for Google Play distribution. Status discovery uses a one-time, Android-managed folder connection: the system picker is directed toward WhatsApp Media and the user confirms **Use this folder**, then **Allow**. The resulting read-only scoped grant persists across launches until the user changes or revokes it.

The release does not request All files access, legacy external-storage permissions, or broad media-library permissions. Saved copies use MediaStore. See [ADR 008](../decisions/008-play-store-scoped-status-access.md) for the policy and implementation decision.

Ordinary pushes and pull requests run validation only. A maintainer must manually request publication and provide the Android signing secrets described in [signing.md](signing.md). Never publish an APK signed with a debug key.

| Document | Purpose |
| --- | --- |
| [github-releases.md](github-releases.md) | Manual publication gate and release assets |
| [signing.md](signing.md) | Android signing and secret handling |
| [release-checklist.md](release-checklist.md) | Checks before signed Android and Google Play distribution |
| [versioning.md](versioning.md) | Release calculation and Conventional Commits |
| [versioning-policy.md](versioning-policy.md) | Version and build number rules |
| [release-strategy.md](release-strategy.md) | Current and future distribution channels |
| [android-developer-verification.md](android-developer-verification.md) | Package ownership and store prerequisites |
