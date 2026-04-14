// ─────────────────────────────────────────────────────────────────────────────
//  api_keys.dart  —  ALL keys live here only
//  Personal use app — not for Play Store
//
//  HOW TO GET EACH KEY:
//  YouTube  → https://console.cloud.google.com → New Project → Enable
//             "YouTube Data API v3" → Credentials → Create API Key
//  Spotify  → https://developer.spotify.com/dashboard → Create App
//             → copy Client ID + Client Secret
//  SoundCloud → https://developers.soundcloud.com → Register → Client ID
//  Jamendo  → https://devportal.jamendo.com → Create App → Client ID
//
//  Audius, Deezer, FMA → NO KEY NEEDED — calls work as-is
// ─────────────────────────────────────────────────────────────────────────────

class ApiKeys {
  ApiKeys._();

  // ── Permanent (never expire) ─────────────────────────────────────────────
  static const String jamendoClientId = 'YOUR_JAMENDO_CLIENT_ID';

  // ── Temporary / quota-based ──────────────────────────────────────────────
  //    These live in lib/services/temporary/ — deleting those files is safe,
  //    the app falls back to permanent sources automatically.

  // YouTube Data API v3 — 10,000 units/day free, resets midnight PST
  static const String youtubeApiKey = 'YOUR_YOUTUBE_API_KEY';

  // Spotify — token auto-refreshes every 60 min, no manual work needed
  static const String spotifyClientId     = 'YOUR_SPOTIFY_CLIENT_ID';
  static const String spotifyClientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';

  // SoundCloud — 15,000 plays/day free
  static const String soundcloudClientId = 'YOUR_SOUNDCLOUD_CLIENT_ID';

  // ── Keys NOT required (leave as-is) ──────────────────────────────────────
  //  Audius      → decentralised, no key
  //  Deezer      → public API, no key
  //  FMA         → public API, no key
}
