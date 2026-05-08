@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  run.bat  —  Local development launcher for Vibelo
REM  Never commit this file to Git (it's already in .gitignore via .env.sh)
REM  Add run.bat to .gitignore if not already there.
REM ─────────────────────────────────────────────────────────────────────────

REM Paste your actual keys below (replace the placeholder values)
set JIOSAAVN_BASE_URL=https://patient-snowflake-d54b.manoj214330.workers.dev
set YOUTUBE_API_KEY=AIzaSyBwjpX905WWG4vw9n_PhRuzXjGTvQOdb1c

flutter run ^
  --dart-define=JIOSAAVN_BASE_URL=%JIOSAAVN_BASE_URL% ^
  --dart-define=YOUTUBE_API_KEY=%YOUTUBE_API_KEY%