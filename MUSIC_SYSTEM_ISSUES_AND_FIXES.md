# Vibelo Music System Audit & Fix Report

## Scope
- Priority source: **JioSaavn first everywhere**
- Fallback source: **YouTube only when JioSaavn fails/returns empty**
- Playback reliability for search and player flows
- Config/env verification for local run

---

## Issues Found

### 1) Audio handler lifecycle instability
**Problem**
- `PlayerProvider` was created using a dummy `VibeleAudioHandler` before `AudioService.init` completed.
- Later reassignment of global handler could leave provider bound to a stale instance.

**Fix applied**
- Moved stable `AudioService.init` to happen before `runApp`.
- Removed duplicate audio init from background initializer.

**Files changed**
- `lib/main.dart`

---

### 2) JioSaavn parsing could include non-playable URLs
**Problem**
- URL extraction could pass through empty/invalid links.
- This can lead to visible results that fail at play time.

**Fix applied**
- Hardened URL extraction in `SongModel.fromJioSaavn()`:
  - Validate `http(s)` URLs.
  - Filter invalid entries.
  - Keep highest-quality valid candidate when available.

**Files changed**
- `lib/models/song_model.dart`

---

### 3) JioSaavn service silently failed without diagnostics
**Problem**
- Failures were swallowed silently, making root cause hard to identify.

**Fix applied**
- Added debug logs for:
  - non-200 responses
  - exceptions
- Filtered out songs with empty `audioUrl` at service layer.

**Files changed**
- `lib/services/jiosaavn_service.dart`

---

### 4) Source policy not strict in language and search flows
**Problem**
- Some flows mixed JioSaavn and YouTube results in parallel.
- This violated strict priority requirement.

**Fix applied**
- Enforced strict priority in `MusicSourceManager`:
  - Try JioSaavn first.
  - Call YouTube only when JioSaavn returns empty.
- Applied to search and language-based fetch methods.

**Files changed**
- `lib/providers/music_source_manager.dart`

---

### 5) YouTube fallback errors were not clearly visible in logs
**Problem**
- Missing API key, HTTP failures, and exceptions were not clearly logged.

**Fix applied**
- Added debug logging in `YouTubeService` for:
  - empty API key
  - non-200 API responses
  - thrown exceptions in search/trending

**Files changed**
- `lib/services/youtube_service.dart`

---

## Final Source Behavior (Now)
1. **JioSaavn queried first** in major flows.
2. If JioSaavn returns playable results, app uses those.
3. **YouTube is used only when JioSaavn is empty/fails**.
4. Playback path remains:
   - JioSaavn → direct URL
   - YouTube → `youtube_explode_dart` stream resolve at play time

---

## Manual Steps You Must Do

## 1) Verify local run command
Use your existing launcher:

```bat
run.bat
```

It should include:
- `JIOSAAVN_BASE_URL=https://your-jiosaavn-proxy-url.workers.dev`
- `YOUTUBE_API_KEY=...` (optional but needed for fallback list fetch)

## 2) Validate JioSaavn-first behavior
In app search:
- Query: `leo`
- Query: `hindi songs`
- Query: `telugu songs`

Expected:
- Results appear from JioSaavn first.
- Tap play should start audio without getting stuck on loader.

## 3) Validate YouTube fallback behavior
Test with a query likely to return no JioSaavn results.

Expected:
- Only then YouTube results appear (if API key valid).
- Playback should resolve stream and play.

## 4) If fallback still does not show songs
Check:
- YouTube API key validity and quota.
- Internet connectivity.
- Debug logs for "YouTube ... failed" lines.

---

## Optional Next Improvements (Recommended)
- Add in-app source badge on each tile: `JioSaavn` / `YouTube fallback`.
- Add retry action on playback failure toast/snackbar.
- Add startup health check ping for JioSaavn endpoint.
- Add simple local diagnostics screen to show last API/playback errors.

---

## Second-pass fixes after runtime logs (2026-05-08)

### A) Fixed JioSaavn parse crash from payload shape changes
**Observed log**
- `type 'String' is not a subtype of type 'int' of 'index'`

**Cause**
- Some JioSaavn fields (`image`, `downloadUrl`) can be `String`, `Map`, or `List` depending on response.

**Fix**
- Parsing now supports String/Map/List safely across:
  - `SongModel.fromJioSaavn`
  - `AlbumModel.fromJioSaavn`
  - `ArtistModel.fromJioSaavn`

### B) Improved YouTube playback for 403 source errors
**Observed log**
- ExoPlayer `HttpDataSource$InvalidResponseCodeException: Response code: 403`

**Cause**
- Some resolved YouTube CDN stream URLs are blocked/expire quickly per client/network.

**Fix**
- Added request headers support in audio layer.
- Player now tries multiple audio-only stream candidates (high→low bitrate) instead of single URL.
- Added browser-like headers (`User-Agent`, `Referer`, `Origin`) for YouTube stream requests.

### C) Validation status
- `flutter analyze` passes with **No issues found**.

---

## Third-pass hard fixes after repeated device logs (2026-05-08)

### 1) AudioService Activity mismatch fixed
**Observed error**
- `PlatformException(... Activity class declared in your AndroidManifest.xml is wrong ... )`

**Fix**
- `MainActivity` now extends `AudioServiceActivity`.
- Removed extra `AudioServiceActivity` declaration from Manifest.

**Files**
- `android/app/src/main/kotlin/com/vibelo/app/MainActivity.kt`
- `android/app/src/main/AndroidManifest.xml`

### 2) JioSaavn crash path fully closed
**Observed error**
- `type 'String' is not a subtype of type 'int' of 'index'`

**Root cause**
- `album` and `primaryArtists` payload shapes vary (String/Map/List).

**Fix**
- Added resilient parsers for album + artists in `SongModel.fromJioSaavn`.

**File**
- `lib/models/song_model.dart`

### 3) Playback continuity when YouTube is hard-blocked (403)
**Observed error**
- Multiple ExoPlayer `403` even after stream retries.

**Fix**
- If all YouTube stream candidates fail, player now auto-queries JioSaavn with
  `song title + artist` and starts first playable result.

**File**
- `lib/providers/player_provider.dart`