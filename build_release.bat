@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  build_release.bat  —  Build release APK with all API keys injected
REM ─────────────────────────────────────────────────────────────────────────

set JAMENDO_CLIENT_ID=9649d556
set JIOSAAVN_BASE_URL=https://patient-snowflake-d54b.manoj214330.workers.dev
set YOUTUBE_API_KEY=AIzaSyBwjpX905WWG4vw9n_PhRuzXjGTvQOdb1c
set SPOTIFY_CLIENT_ID=AIzaSyBwjpX905WWG4vw9n_PhRuzXjGTvQOdb1c
set SPOTIFY_CLIENT_SECRET=30af9930e33f43c189d7b71ca9affa70

flutter build apk --release ^
  --dart-define=JAMENDO_CLIENT_ID=%JAMENDO_CLIENT_ID% ^
  --dart-define=JIOSAAVN_BASE_URL=%JIOSAAVN_BASE_URL% ^
  --dart-define=YOUTUBE_API_KEY=%YOUTUBE_API_KEY% ^
  --dart-define=SPOTIFY_CLIENT_ID=%SPOTIFY_CLIENT_ID% ^
  --dart-define=SPOTIFY_CLIENT_SECRET=%SPOTIFY_CLIENT_SECRET%

echo.
echo ✓ APK built at: build\app\outputs\flutter-apk\app-release.apk
