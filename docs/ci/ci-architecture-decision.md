# CI and release architecture decision

**Status:** Approved  
**Product:** WA Status Downloader

Ordinary pushes and pull requests perform read-only validation with `contents: read`. They build a debug APK and never receive release signing credentials.

Publishing is an explicit manual action. A workflow dispatch must set `publish_release: true`; only the tag and publish jobs receive `contents: write`. Android upload credentials are decoded into the runner's temporary directory and an ephemeral `android/key.properties` is created for the signed build.

Release Gradle tasks fail when valid upload signing configuration is absent. This prevents accidental debug-signed release artifacts.

iOS packaging is optional and runs only when Apple certificate and provisioning profile secrets are configured.
