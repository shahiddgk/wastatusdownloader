# Android release signing

## Local configuration

The local upload key is stored outside version control:

```text
android/upload-keystore.jks
android/key.properties
```

Both paths are ignored by Git. The current key uses alias `upload`, RSA 4096, and a long validity period.

`android/key.properties` has this shape:

```properties
keyAlias=upload
keyPassword=...
storePassword=...
storeFile=/absolute/path/to/android/upload-keystore.jks
```

Gradle configures release signing only when all properties are present and the keystore file exists. Any release task fails when signing is unavailable. Debug builds continue to use the standard debug key.

Back up the keystore and both passwords in encrypted storage before distributing an APK or registering the upload certificate. Losing the key can prevent future updates outside a store-managed key recovery process.

## CI configuration

Create these GitHub Actions secrets:

- `ANDROID_UPLOAD_KEYSTORE_BASE64`: Base64 encoding of the JKS file
- `ANDROID_UPLOAD_STORE_PASSWORD`: keystore password
- `ANDROID_UPLOAD_KEY_PASSWORD`: private key password

The workflow decodes the key into `$RUNNER_TEMP`, creates an ephemeral properties file, confirms alias `upload`, and verifies the signed APK.

Never commit a keystore, signing property file, password, certificate private key, or Base64 keystore value.
