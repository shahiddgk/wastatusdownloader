# Android distribution readiness

**Package:** `ratedwhats.appstatusdownloader`

The maintainer must register this exact package in any target store and complete the store's current identity, contact, tax, and policy requirements.

## Signed Android artifacts

Publish only release-signed APKs. Provide a SHA-256 checksum for direct downloads and retain an encrypted backup of the upload keystore and credentials. Verify the signature, package ID, version, label, minimum SDK, and permissions from the final APK/AAB.

## Google Play

The current build uses a user-confirmed, persisted Storage Access Framework grant for WhatsApp Media. Verify the final upload artifact does not request `MANAGE_EXTERNAL_STORAGE`, legacy read/write external-storage permissions, or broad media-library permissions. Package registration or a successful AAB build does not establish policy eligibility; the final store listing, declarations, and binary must still match.

If Play App Signing is enabled, register the public certificate for the `upload` key and keep the private key outside the repository.

## Repository boundaries

Do not commit identity documents, signing secrets, private certificates, service-account credentials, or console exports. Store account creation and policy declarations remain manual maintainer actions.
