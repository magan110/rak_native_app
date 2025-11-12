# Keystore instructions

This folder is the intended place to store your Android signing keystore file.

DO NOT commit the keystore to version control if it contains real signing keys. Keep a backup in a secure location.

Steps to create a keystore (run locally on your machine):

1. Create the `keystores/` folder in the project root (already present).
2. Run the following command in PowerShell from the project root to generate a keystore named `rak_keystore.jks`:

```powershell
keytool -genkeypair -v -keystore keystores/rak_keystore.jks -alias rak_key -keyalg RSA -keysize 2048 -validity 10000
```

When prompted, enter the passwords for the keystore and key. You can reuse the `storePassword` and `keyPassword` values already placed in `key.properties` (project root), or provide new ones.

3. Verify the file exists:

```powershell
Test-Path .\keystores\rak_keystore.jks
```

4. Build a signed Android App Bundle (AAB) using Flutter (this will use the signing config defined in `android/app/build.gradle.kts` which reads `key.properties`):

```powershell
flutter build appbundle --release
```

5. The produced bundle will be at `build/app/outputs/bundle/release/app-release.aab` (or a similar path shown in the build output). Upload that file to the Play Console.

Notes & safety
- `key.properties` (project root) holds the store/key passwords and is already listed in `.gitignore`.
- Keep an offline backup of your keystore and passwords — losing them prevents publishing updates to the same app on the Play Store.
- Make sure `applicationId` in `android/app/build.gradle.kts` is set to your unique package name (not `com.example...`).
- Verify `version:` in `pubspec.yaml` is correct and increment `+buildNumber` for each Play Store release.

If you want, I can:
- create the empty `keystores/` directory in the repo (already created by this README addition),
- generate the exact `keytool` command with the passwords from `key.properties` (you must confirm you want those embedded in a command), or
- update `android/app/build.gradle.kts` to use a different `applicationId` if you provide the desired package name.
