# Vibelo App — Complete Setup Guide
## Follow these steps in ORDER

---

## STEP 1 — Get Your Jamendo API Key (Free, 5 min)

1. Go to: https://devportal.jamendo.com/
2. Click "Create Account" and register
3. After login → click "My Applications"
4. Click "Create Application"
5. Fill in: Name = "Vibelo", Type = "Android App"
6. Copy your **Client ID**
7. Open: `lib/services/jamendo_service.dart`
8. Replace `YOUR_CLIENT_ID` with your actual Client ID

---

## STEP 2 — Create Firebase Project (Free, 10 min)

1. Go to: https://console.firebase.google.com/
2. Click "Create a project" → Name it "Vibelo"
3. Disable Google Analytics (not needed)
4. Click "Create"

### Enable Authentication:
- Left menu → Authentication → Get Started
- Sign-in method → Enable these:
  - Email/Password ✅
  - Google ✅
  - Anonymous ✅

### Create Firestore Database:
- Left menu → Firestore Database → Create Database
- Select "Start in test mode" (for now)
- Choose "asia-south1 (Mumbai)" for India users
- Click "Enable"

### Add Android App to Firebase:
- Click gear icon → Project settings
- Click "Add app" → Android icon
- Package name: `com.vibelo.app`
- Nickname: `Vibelo Android`
- Click "Register App"
- Download `google-services.json`
- Put it in: `android/app/google-services.json`

---

## STEP 3 — Configure Android Files

### android/build.gradle — add this to the END:
```gradle
plugins {
    id 'com.google.gms.google-services' version '4.4.0' apply false
}
```

### android/app/build.gradle — make sure these exist:
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        applicationId "com.vibelo.app"
        minSdkVersion 21
        targetSdkVersion 34
        multiDexEnabled true
    }
}

dependencies {
    implementation 'com.android.support:multidex:1.0.3'
}
```

### Add at TOP of android/app/build.gradle:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### android/app/src/main/AndroidManifest.xml — add inside <manifest>:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### Also inside <application> in AndroidManifest.xml:
```xml
android:label="Vibelo"
android:usesCleartextTraffic="true"
```

### Add this service inside <application> for background audio:
```xml
<service android:name="com.ryanheise.audioservice.AudioServiceActivity"
    android:exported="true"/>
```

---

## STEP 4 — Enable Google Sign-In SHA Key

1. Run in terminal (inside vibelo folder):
```
cd android
./gradlew signingReport
```
2. Copy the **SHA1** key
3. Firebase Console → Project Settings → Your Android App
4. Add fingerprint → paste SHA1 → Save

---

## STEP 5 — Install packages and run

```bash
cd vibelo
flutter pub get
flutter run
```

---

## STEP 6 — Enable Google Fonts (Internet needed)

The app uses Google Fonts. For offline use, add to pubspec.yaml:
```yaml
flutter:
  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-Regular.ttf
        - asset: assets/fonts/Poppins-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Poppins-Bold.ttf
          weight: 700
```

---

## FILE STRUCTURE

```
vibelo/
├── lib/
│   ├── main.dart                    ← App entry point
│   ├── theme/
│   │   └── app_theme.dart           ← Colors & theme
│   ├── models/
│   │   ├── song_model.dart          ← Song data model
│   │   └── user_model.dart          ← User data model
│   ├── services/
│   │   ├── auth_service.dart        ← Firebase auth
│   │   ├── jamendo_service.dart     ← Free music API ← PUT CLIENT ID HERE
│   │   └── audio_handler.dart       ← Background playback
│   ├── providers/
│   │   ├── auth_provider.dart       ← Auth state
│   │   ├── music_provider.dart      ← Songs state
│   │   └── player_provider.dart     ← Player state
│   ├── screens/
│   │   ├── splash_screen.dart       ← Launch screen
│   │   ├── onboarding_screen.dart   ← 3-page intro
│   │   ├── main_screen.dart         ← Nav + layout
│   │   ├── home_screen.dart         ← Home + trending
│   │   ├── search_screen.dart       ← Search + genres
│   │   ├── library_screen.dart      ← Liked + playlists
│   │   ├── player_screen.dart       ← Full player + EQ + sleep
│   │   ├── profile_screen.dart      ← Profile + premium
│   │   └── auth/
│   │       ├── login_screen.dart    ← Login
│   │       └── signup_screen.dart   ← Register
│   └── widgets/
│       ├── mini_player.dart         ← Bottom mini bar
│       └── song_tile.dart           ← Song list item
└── android/
    └── app/
        └── google-services.json     ← Download from Firebase
```

---

## MUSIC SOURCE — 100% COPYRIGHT-FREE

All music comes from **Jamendo** — Creative Commons licensed.
- Artists freely share their music under CC licenses
- You can use, stream, and play it legally
- No copyright issues for your app
- License info: https://www.jamendo.com/legal/creative-commons

---

## QUESTIONS?

If you get any error, share the exact error message and I will fix it for you!
