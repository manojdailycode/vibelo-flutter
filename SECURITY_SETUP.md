# Vibelo — Security Setup Step-by-Step

This file describes exactly what to do, step by step, to secure Google sign-in, Firebase config, and the Jamendo API key.

## Step 1: Create a release keystore

Run this once on your local machine.

For macOS / Linux:
```bash
keytool -genkeypair -v \
  -keystore vibelo-release.keystore \
  -alias vibelo \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD \
  -dname "CN=Vibelo, OU=Dev, O=ManojKumar, L=Tirupati, ST=AP, C=IN"
```

For Windows PowerShell:
```powershell
keytool -genkeypair -v -keystore vibelo-release.keystore -alias vibelo -keyalg RSA -keysize 2048 -validity 10000 -storepass YOUR_STORE_PASSWORD -keypass YOUR_KEY_PASSWORD -dname "CN=Vibelo, OU=Dev, O=ManojKumar, L=Tirupati, ST=AP, C=IN"
```

Keep `YOUR_STORE_PASSWORD` and `YOUR_KEY_PASSWORD` safe.
- `YOUR_STORE_PASSWORD` is the password you choose for the keystore file.
- `YOUR_KEY_PASSWORD` is the password you choose for the key inside the keystore.
- Use simple but secure values you can remember or store in a password manager.

## Step 2: Get the SHA-1 fingerprint

Run:

```bash
keytool -list -v \
  -keystore vibelo-release.keystore \
  -alias vibelo \
  -storepass YOUR_STORE_PASSWORD
```

Copy the `SHA1:` value.

## Step 3: Add SHA-1 to Firebase

1. Open Firebase Console.
2. Select your project.
3. Go to Project Settings → Android app.
4. Add the SHA-1 fingerprint.
5. Download the new `google-services.json`.

## Step 4: Place files locally

Put local secret files in the project:

- `android/app/google-services.json`
- `android/key.properties`

`android/key.properties` should contain:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=vibelo
storeFile=vibelo-release.keystore
```

- `YOUR_STORE_PASSWORD` and `YOUR_KEY_PASSWORD` are passwords you create yourself.
- They are not provided by Firebase or the project.
- They must match the values used when you created `vibelo-release.keystore`.

Never commit these files.

## Step 5: Confirm `.gitignore` is set

Ensure `.gitignore` contains:

```gitignore
android/app/google-services.json
android/key.properties
*.keystore
*.jks
.env
.env.sh
```

This project already has those ignore rules in `.gitignore`.

## Step 6: Add GitHub secrets

Go to GitHub repo settings → Secrets and variables → Actions and add the following values based on your local files and keystore:

- `FIREBASE_CONFIG_BASE64` — base64 of `android/app/google-services.json`
- `KEYSTORE_BASE64` — base64 of `vibelo-release.keystore`
- `KEYSTORE_PASSWORD` — the password you chose for the keystore
- `KEY_PASSWORD` — the password you chose for the key inside the keystore
- `KEY_ALIAS` — `vibelo`
- `JAMENDO_CLIENT_ID` — your Jamendo API client ID

## Step 7: Encode secrets for GitHub

Convert the local secret files into base64 text and paste them into GitHub secrets.

- `KEYSTORE_BASE64` comes from `vibelo-release.keystore`
- `FIREBASE_CONFIG_BASE64` comes from `android/app/google-services.json`

On Windows PowerShell, use `Set-Clipboard` to copy the output and paste it directly into GitHub.
On macOS/Linux, use `pbcopy` after encoding.

## Step 8: Run locally with the API key

For local development and release builds, pass the Jamendo client ID at compile time:

- `flutter run --dart-define=JAMENDO_CLIENT_ID=your_key_here`
- `flutter build apk --release --dart-define=JAMENDO_CLIENT_ID=your_key_here`

This keeps the API client ID out of source code.

## Step 9: Confirm code is secure

Verify the app uses secure patterns:

- `lib/services/jamendo_service.dart` reads `JAMENDO_CLIENT_ID` from `String.fromEnvironment`
- no Jamendo API key is hardcoded
- `android/app/build.gradle.kts` uses `key.properties` for release signing when present

## Summary

Do this in order:

1. create `vibelo-release.keystore`
2. get SHA-1
3. update Firebase and download `google-services.json`
4. add `android/app/google-services.json` locally
5. add `android/key.properties` locally
6. add GitHub secrets
7. run locally with `--dart-define`
8. build release and test Google Sign-In

This single file contains the exact process to follow.