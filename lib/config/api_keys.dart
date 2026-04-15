// ─────────────────────────────────────────────────────────────────────────────
//  api_keys.dart  —  ALL keys live here only
//  Personal use app — not for Play Store
//
//  HOW TO GET EACH KEY:
//  YouTube  → https://console.cloud.google.com → New Project → Enable
//             "YouTube Data API v3" → Credentials → Create API Key
//  Spotify  → https://developer.spotify.com/dashboard → Create App
//             → copy Client ID + Client Secret
//  Jamendo  → https://devportal.jamendo.com → Create App → Client ID
//
//  Audius, Deezer, FMA → NO KEY NEEDED — calls work as-is
// ─────────────────────────────────────────────────────────────────────────────

class ApiKeys {
  ApiKeys._();
  // ── Temporary / quota-based ──────────────────────────────────────────────
  //    These live in lib/services/temporary/ — deleting those files is safe,
  //    the app falls back to permanent sources automatically.

  // YouTube Data API v3 — 10,000 units/day free, resets midnight PST
  static const String youtubeApiKey = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: '',
  );

  // Spotify — token auto-refreshes every 60 min, no manual work needed
  static const String spotifyClientId = String.fromEnvironment(
    'SPOTIFY_CLIENT_ID',
    defaultValue: '',
  );
  static const String spotifyClientSecret = String.fromEnvironment(
    'SPOTIFY_CLIENT_SECRET',
    defaultValue: '',
  );

  // Jamendo — Free tier for developers
  static const String jamendoClientId =
      String.fromEnvironment('JAMENDO_CLIENT_ID', defaultValue: '');

  // ── Keys NOT required (leave as-is) ──────────────────────────────────────
  //  Audius      → decentralised, no key
  //  Deezer      → public API, no key
  //  FMA         → public API, no key
}
