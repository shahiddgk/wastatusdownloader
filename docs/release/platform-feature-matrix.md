# Platform feature matrix

| Capability | Android | iOS | Notes |
| --- | --- | --- | --- |
| Flutter interface and themes | Implemented | Builds in Flutter | iOS device behavior still requires verification |
| WhatsApp status discovery | Implemented | Unavailable | Android native scanner reads known shared-storage locations |
| WhatsApp Business discovery | Implemented | Unavailable | Android only |
| Photo preview | Implemented | UI available | Depends on a usable media source |
| Video playback | Implemented | UI available | Uses platform video player |
| Save to public gallery | Implemented | Not implemented | Android uses MediaStore |
| Native sharing | Implemented | Not implemented | Current platform channel is Android only |
| Local status labels | Implemented | Implemented in Dart | Stored in app preferences |
| One-time scoped WhatsApp Media connection | Implemented | Not applicable | Android system picker persists a read-only selected-folder grant |
| Offline operation | Implemented | Implemented | Android manifest has no internet permission |

Android is the supported product target. The iOS project is maintained for build compatibility where practical, but it does not provide WhatsApp status discovery.
