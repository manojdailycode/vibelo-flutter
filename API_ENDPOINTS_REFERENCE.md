# 🎵 Vibelo API Endpoints Reference

**Last Updated:** May 7, 2026  
**Project:** Vibelo Flutter Music App

---

## 📋 Quick Reference Table

| API | Type | Base URL | Auth | Timeout | Status |
|-----|------|----------|------|---------|--------|
| **JioSaavn** | Music | `{JIOSAAVN_BASE_URL}` | None | 10s | ✅ Primary |
| **YouTube** | Music + Video | `https://www.googleapis.com` | API Key | Default | ✅ Fallback |
| **LRCLIB** | Lyrics | `https://lrclib.net` | None | 8s | ✅ Free |
| **Firebase Auth** | Auth | Backend-as-Service | OAuth/Email | Default | ✅ Active |
| **Firestore** | Database | Backend-as-Service | Auth Token | Default | ✅ Active |

---

## 🔍 API Details

### 1️⃣ JioSaavn API (Primary Music Source)

```
BASE_URL: {Environment: JIOSAAVN_BASE_URL}
Default: https://saavn.dev

Endpoints:
  POST /api/search/songs
    params: query, limit
    response: { data: { results: SongModel[] } }
  
  POST /api/search/albums
    params: query, limit
    response: { data: { results: AlbumModel[] } }
  
  POST /api/search/artists
    params: query, limit
    response: { data: { results: ArtistModel[] } }
```

**Service:** `lib/services/jiosaavn_service.dart`  
**Timeout:** 10 seconds  
**Error Handling:** Silently fails, returns `[]`

---

### 2️⃣ YouTube Data API v3

```
BASE_URL: https://www.googleapis.com/youtube/v3

Endpoints:
  GET /search
    params: part=snippet, q, type=video, maxResults, key={YOUTUBE_API_KEY}
    response: { items: [] }
  
  GET /videos
    params: part=snippet,contentDetails, chart=mostPopular, 
            videoCategoryId=10, regionCode, maxResults, key={YOUTUBE_API_KEY}
    response: { items: [] }
```

**Service:** `lib/services/youtube_service.dart`  
**Auth:** API Key (environment: `YOUTUBE_API_KEY`)  
**Quota:** 10,000 units/day  
**Playback Scheme:** `youtube://{videoId}` (custom, resolved at playback)

---

### 3️⃣ LRCLIB (Free Lyrics API)

```
BASE_URL: https://lrclib.net

Endpoints:
  GET /get
    params: track_name, artist_name, duration
    response: { syncedLyrics, plainLyrics }
  
  GET /search
    params: track_name, artist_name
    response: [ { plainLyrics, syncedLyrics } ]
```

**Service:** `lib/services/lyrics_service.dart`  
**Auth:** None (public API)  
**Timeout:** 8 seconds  
**Format:** LRC format `[mm:ss.xx] lyric text`

---

### 4️⃣ Firebase Authentication

```
Services:
  - Email/Password Auth
  - Google OAuth
  - Anonymous/Guest Auth

Collections:
  - users/{uid}              // Profile data
  - users/{uid}/playlists    // User playlists
```

**Service:** `lib/services/auth_service.dart`  
**Config:** `android/app/google-services.json`

---

### 5️⃣ Firebase Firestore

```
Collections:
  
  users/{uid}
    ├── displayName: String
    ├── email: String
    └── createdAt: Timestamp
  
  users/{uid}/playlists/{playlistId}
    ├── id: String
    ├── name: String
    ├── emoji: String
    ├── songs: SongModel[]
    └── createdAt: Timestamp
```

**Service:** `lib/services/playlist_service.dart`

---

## 🔐 Environment Variables

### `.env` File Required
Location: Root directory (`.env.example` provided)

```env
# JioSaavn API (Required)
JIOSAAVN_BASE_URL=https://your-jiosaavn-proxy-url.workers.dev

# YouTube API (Optional)
YOUTUBE_API_KEY=your_youtube_api_key_here

# Firebase (Auto-loaded from google-services.json)
```

### How to Use
```bash
# Development
run.bat

# Production Build
build_release.bat

# Manual Flutter Command
flutter run --dart-define-from-file=.env
```

---

## 🎯 Main Provider

**File:** `lib/providers/music_source_manager.dart`

```dart
MusicSourceManager.instance.searchAll(query);     // Multi-source search
MusicSourceManager.instance.getTrending();        // Trending songs
MusicSourceManager.instance.getNewReleases();     // New releases
MusicSourceManager.instance.loadHomeData();       // Parallel load
MusicSourceManager.instance.getSongsByLanguage(); // Language filter
```

---

## 📦 Key Dependencies

```yaml
http: ^1.2.1                  # HTTP requests
firebase_core: ^3.1.0         # Firebase
firebase_auth: ^5.1.0         # Auth
cloud_firestore: ^5.0.0       # Database
google_sign_in: ^6.2.1        # OAuth
youtube_explode_dart: ^2.2.2  # YouTube extraction
just_audio: ^0.9.40           # Audio playback
audio_service: ^0.18.14       # Background service
```

---

## 🚀 Setup Instructions

### 1. Clone & Install
```bash
git clone <repo>
cd vibeloflutter
flutter pub get
```

### 2. Create `.env` File
```bash
copy .env.example .env
```

### 3. Fill in API Keys
```env
JIOSAAVN_BASE_URL=<your-proxy-url>
YOUTUBE_API_KEY=<your-youtube-api-key>
```

### 4. Setup Firebase
- Download `google-services.json` from Firebase Console
- Place at: `android/app/google-services.json`

### 5. Run
```bash
run.bat
```

---

## ✅ Permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

---

## 📊 API Hierarchy

```
MusicSourceManager (Orchestrator)
├── JioSaavnService (Primary)
│   └── /api/search/* endpoints
├── YouTubeService (Fallback)
│   └── /youtube/v3/* endpoints
├── LyricsService (Helper)
│   └── lrclib.net endpoints
├── AuthService
│   └── Firebase Authentication
└── PlaylistService
    └── Firestore Collections
```

---

## ⚠️ Common Issues & Solutions

### Issue: `.env` file not found
**Solution:** Run `copy .env.example .env` from root directory

### Issue: API key is empty
**Solution:** Ensure `--dart-define-from-file=.env` is used (automatic in run.bat)

### Issue: YouTube API not working
**Solution:** Check quota (10K units/day), verify API key in `.env`

### Issue: JioSaavn proxy not responding
**Solution:** Verify `JIOSAAVN_BASE_URL` is correct and proxy is running

### Issue: Firestore authentication fails
**Solution:** Verify `google-services.json` is in correct location

---

## 📞 API Support

- **JioSaavn:** Deploy own proxy (Vercel/Railway/Cloudflare Workers)
- **YouTube:** https://console.cloud.google.com
- **LRCLIB:** Public API, no support needed
- **Firebase:** https://console.firebase.google.com

---

**All endpoints mapped and verified ✅**
