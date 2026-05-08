# Vibelo Changelog

## v1.1.0 (build 2) — Bug Fix Release

### Fixed
- **Onboarding loop** — Onboarding was showing on every launch. Now shows only on first install; afterwards the app navigates directly to Login or Home.
- **Login not persisting** — Firebase auth state was read before the async stream fired. Now uses `FirebaseAuth.instance.currentUser` (synchronous, always correct after `Firebase.initializeApp()`).
- **Play button stuck on loading spinner** — Added `try/finally` to `playSong()` so `isLoading` is always cleared. Also separated "loading a new song" from "audio buffering" state so the play/pause icon shows the moment audio is ready.
- **Queue screen missing album art** — Replaced plain `CircleAvatar` with `CachedNetworkImage` so every song in the queue shows its artwork.
- **Profile edit not working** — Wired up the edit icon and added an "Edit Profile" settings row. Opens a bottom sheet where users can change their display name and profile photo URL, with immediate local state update and Firestore persistence.

---

## v1.0.0 (build 1) — Initial Release
- Jamendo API integration (royalty-free streaming)
- Firebase Auth (Email, Google, Anonymous)
- Background audio via `audio_service` + `just_audio`
- Home, Search, Library, Profile screens
- Full-screen player with Equalizer and Sleep Timer
- 5 themes (Dark base), Poppins typography
