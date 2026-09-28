# Android distribution readiness

**Package:** `ratedwhats.appstatusdownloader`

The maintainer must register this exact package in any target store and complete the store's current identity, contact, tax, and policy requirements.

## Direct APK distribution

Publish only release-signed APKs. Provide a SHA-256 checksum and retain an encrypted backup of the upload keystore and credentials. Verify the signature, package ID, version, label, and permissions from the final APK.

## Google Play

The current build declares `MANAGE_EXTERNAL_STORAGE`. Google Play restricts All files access and requires an eligible core use case plus an approved declaration. Package registration or a successful AAB build does not establish policy eligibility.

If Play App Signing is enabled, register the public certificate for the `upload` key and keep the private key outside the repository.

## Repository boundaries

Do not commit identity documents, signing secrets, private certificates, service-account credentials, or console exports. Store account creation and policy declarations remain manual maintainer actions.
