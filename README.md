# 🎵 Vibelo - Stream. Discover. Vibe.

[![Build & Release APK](https://github.com/manojdailycode/vibelo/actions/workflows/build-apk.yml/badge.svg)](https://github.com/manojdailycode/vibelo/actions/workflows/build-apk.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.32.0-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.2.0-blue?logo=dart)](https://dart.dev)

A modern, full-featured music streaming app built with Flutter. Stream royalty-free music from **Jamendo**, enjoy seamless background playback, customize your experience with themes, and manage your library with ease.

## ✨ Key Features

- **🎶 Royalty-Free Music Streaming** via Jamendo API
- **🔐 Multiple Authentication Methods** — Email, Google Sign-In, Anonymous
- **🎧 Background Audio Playback** with `audio_service` + `just_audio`
- **📱 Beautiful UI** with 5 themes (Dark base) and Poppins typography
- **🎯 Full-Screen Player** with Equalizer and Sleep Timer
- **🏠 Home, Search, Library & Profile** screens
- **📋 Dynamic Queue Management** with album artwork
- **👤 User Profiles** with customizable display name and photo
- **🔄 Login Persistence** with secure Firebase Authentication
- **✅ Latest v1.1.0** — Bug fixes for onboarding, login, play button, queue artwork, profile editing

## 📥 Installation

### From GitHub Release
1. Download the latest **Vibelo-v1.1.0.apk** from [Releases](https://github.com/manojdailycode/vibelo/releases)
2. Enable **Install from unknown sources** in Android Settings
3. Tap the APK file to install
4. **Android 6.0+** (API 23+) required

### From Source

#### Prerequisites
- [Flutter 3.32.0+](https://flutter.dev/docs/get-started/install)
- [Dart 3.2.0+](https://dart.dev/get-started)
- Android SDK 21+ or iOS 11.0+
- Firebase project with authentication enabled

#### Setup Steps

```bash
# 1. Clone the repository
git clone https://github.com/manojdailycode/vibelo.git
cd vibelo

# 2. Install dependencies
flutter pub get

# 3. Generate app icons (optional, only if modifying)
dart run flutter_launcher_icons

# 4. Run the app
flutter run

# 5. Build APK (optional)
flutter build apk --release
```

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point & theme setup
├── providers/                # State management (Provider)
│   ├── auth_provider.dart    # Authentication states
│   └── player_provider.dart  # Music player states
├── screens/                  # UI screens
│   ├── splash_screen.dart    # Splash/loading screen
│   ├── onboarding_screen.dart # First-time user flow
│   ├── main_screen.dart      # Bottom navigation hub
│   ├── home_screen.dart      # Featured music & playlists
│   ├── search_screen.dart    # Song/artist search
│   ├── profile_screen.dart   # User profile & settings
│   └── player_screen.dart    # Full-screen player
├── services/                 # API & backend services
│   ├── auth_service.dart     # Firebase auth logic
│   └── playlist_service.dart # Jamendo API integration
├── theme/                    # Theming & styling
│   └── themes.dart           # 5 theme definitions
└── widgets/                  # Reusable UI components
    └── song_tile.dart        # Song list item
```

## 🔧 Configuration

### Firebase Setup
1. Create a [Firebase project](https://firebase.google.com/console)
2. Download `google-services.json` and place in `android/app/`
3. Configure iOS via Firebase Console
4. Enable authentication methods:
   - Email/Password
   - Google Sign-In
   - Anonymous

### Jamendo API
- API key is fetched from Jamendo's free tier
- No configuration needed — ready to stream!

## 🛠️ Build & Release

### Local APK Build
```bash
flutter build apk --release
```

### GitHub Actions (Automated)
On every push to `main`:
- Builds release APK automatically
- Uploads to GitHub Releases
- Download-ready for users

## 📚 Tech Stack

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter 3.32.0 |
| **Language** | Dart 3.2.0+ |
| **State Management** | Provider 6.1.2 |
| **Audio Playback** | just_audio 0.9.40, audio_service 0.18.14 |
| **Backend** | Firebase Auth, Firestore, Cloud Storage |
| **API** | Jamendo Radios & Search API |
| **Authentication** | FirebaseAuth (Email, Google, Anonymous) |
| **Image Caching** | cached_network_image 3.3.1 |
| **HTTP Client** | http 1.2.1 |

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Steps to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/awesome-feature`)
3. Commit changes (`git commit -m 'feat: add awesome feature'`)
4. Push to branch (`git push origin feature/awesome-feature`)
5. Open a Pull Request

## 🐛 Bug Reports & Feature Requests

- **Found a bug?** Open an [Issue](https://github.com/manojdailycode/vibelo/issues/new?template=bug_report.md)
- **Have an idea?** Open a [Feature Request](https://github.com/manojdailycode/vibelo/issues/new?template=feature_request.md)

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for release notes and version history.

### Latest Release: v1.1.0
- ✅ Fixed onboarding loop
- ✅ Fixed login persistence
- ✅ Fixed play button spinner state
- ✅ Added album artwork to queue
- ✅ Enabled profile editing

## 📄 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) file for details.

You're free to use, modify, and distribute this app for personal and commercial purposes.

## 👨‍💻 Author

**Manoj Gautam** — [@manojdailycode](https://github.com/manojdailycode)

## 🙏 Acknowledgments

- [Jamendo](https://www.jamendo.com/) for royalty-free music
- [Firebase](https://firebase.google.com/) for authentication & backend
- [Flutter](https://flutter.dev/) & [Dart](https://dart.dev/) communities

## 📮 Contact & Support

- **GitHub:** [@manojdailycode](https://github.com/manojdailycode)
- **Email:** Direct message via GitHub
- **Issues:** [GitHub Issues](https://github.com/manojdailycode/vibelo/issues)

---

**Happy listening! 🎵**
