// ─────────────────────────────────────────────────────────────────────────────
//  api_keys.dart  —  ALL keys live here only, injected at compile time
//
//  LOCAL:  use run.bat  (never commit that file)
//  CI/CD:  set GitHub Secrets, they are passed via --dart-define in build-apk.yml
//
//  HOW TO GET EACH KEY:
//  YouTube  → https://console.cloud.google.com
//             New Project → Enable "YouTube Data API v3" → Create API Key
//  Spotify  → https://developer.spotify.com/dashboard → Create App
//             → copy Client ID + Client Secret
//  Jamendo  → https://devportal.jamendo.com → Create App → Client ID
//  JioSaavn → Deploy https://github.com/sumitkolhe/jiosaavn-api to Vercel/Railway
//             → copy the deployment URL as JIOSAAVN_BASE_URL
// ─────────────────────────────────────────────────────────────────────────────

class ApiKeys {
  ApiKeys._();

  // ── YouTube Data API v3 — 10,000 units/day free ───────────────────────────
  static const String youtubeApiKey = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: '',
  );

  // ── Spotify — Client Credentials flow, token auto-refreshes every 60 min ──
  static const String spotifyClientId = String.fromEnvironment(
    'SPOTIFY_CLIENT_ID',
    defaultValue: '',
  );
  static const String spotifyClientSecret = String.fromEnvironment(
    'SPOTIFY_CLIENT_SECRET',
    defaultValue: '',
  );

  // ── Jamendo — Free developer tier, full audio streams ────────────────────
  static const String jamendoClientId = String.fromEnvironment(
    'JAMENDO_CLIENT_ID',
    defaultValue: '',
  );

  // ── Quick availability checks ─────────────────────────────────────────────
  static bool get hasYoutube   => youtubeApiKey.isNotEmpty;
  static bool get hasSpotify   => spotifyClientId.isNotEmpty && spotifyClientSecret.isNotEmpty;
  static bool get hasJamendo   => jamendoClientId.isNotEmpty;
}
