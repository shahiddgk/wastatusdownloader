# Design asset inventory

The active runtime asset directories are registered in `pubspec.yaml`.

| Directory | Contents |
| --- | --- |
| `assets/icon/` | WA Status Downloader icon sources |
| `assets/onboarding/` | Permission and first-run illustrations |
| `assets/empty/` | Empty, saved, and access-required states |
| `assets/illustrations/` | Privacy, duplicate, and save-success feedback |
| `assets/fonts/` | Plus Jakarta Sans variable font |

Store artwork under `assets/store/` is maintained for distribution and is not included in the Flutter runtime bundle.

Native Android and iOS launcher resources are packaged from the current `launcher_icon.png` master. See [launcher icon notes](../../assets/icon/launcher-icon.md).
