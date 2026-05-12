@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  build_release.bat  —  Build release APK with all API keys injected
REM ─────────────────────────────────────────────────────────────────────────

REM Uses the .env file in the project root.
flutter build apk --release ^
  --dart-define-from-file=.env

echo.
echo ✓ APK built at: build\app\outputs\flutter-apk\app-release.apk
