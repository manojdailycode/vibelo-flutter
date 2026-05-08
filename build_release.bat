@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  build_release.bat  —  Build release APK with all API keys injected
REM  Loads values from .env so secrets are not hardcoded in this file.
REM ─────────────────────────────────────────────────────────────────────────

if not exist .env (
  echo ERROR: .env file not found. Copy .env.example to .env and fill values.
  exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%A in (".env") do (
  if not "%%A"=="" if /i not "%%A:~0,1%%"=="#" set "%%A=%%B"
)

if "%JIOSAAVN_BASE_URL%"=="" (
  echo ERROR: JIOSAAVN_BASE_URL is missing in .env
  exit /b 1
)

flutter build apk --release ^
  --dart-define=JAMENDO_CLIENT_ID=%JAMENDO_CLIENT_ID% ^
  --dart-define=JIOSAAVN_BASE_URL=%JIOSAAVN_BASE_URL% ^
  --dart-define=YOUTUBE_API_KEY=%YOUTUBE_API_KEY% ^
  --dart-define=SPOTIFY_CLIENT_ID=%SPOTIFY_CLIENT_ID% ^
  --dart-define=SPOTIFY_CLIENT_SECRET=%SPOTIFY_CLIENT_SECRET%

echo.
echo ✓ APK built at: build\app\outputs\flutter-apk\app-release.apk
