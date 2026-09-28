# WA Status Downloader release engineering

**Product:** WA Status Downloader  
**Android launcher label:** WA Saver  
**Android application ID:** `ratedwhats.appstatusdownloader`  
**License:** Apache-2.0

The current Android build is intended for direct APK installation. It uses the user-granted All files access permission for automatic status discovery, as recorded in [decision 007](../decisions/007-permission-only-status-access.md). This build is not approved for Google Play distribution. A Play release needs a separately reviewed storage strategy and permission policy check.

Ordinary pushes and pull requests run validation only. A maintainer must manually request publication and provide the Android signing secrets described in [signing.md](signing.md). Never publish an APK signed with a debug key.

| Document | Purpose |
| --- | --- |
| [github-releases.md](github-releases.md) | Manual publication gate and release assets |
| [signing.md](signing.md) | Android signing and secret handling |
| [release-checklist.md](release-checklist.md) | Checks before direct APK distribution |
| [versioning.md](versioning.md) | Release calculation and Conventional Commits |
| [versioning-policy.md](versioning-policy.md) | Version and build number rules |
| [release-strategy.md](release-strategy.md) | Current and future distribution channels |
| [android-developer-verification.md](android-developer-verification.md) | Package ownership and store prerequisites |
