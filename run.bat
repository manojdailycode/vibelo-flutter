@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  run.bat  —  Local development launcher for Vibelo
REM  Never commit this file to Git (it's already in .gitignore via .env.sh)
REM  Add run.bat to .gitignore if not already there.
REM ─────────────────────────────────────────────────────────────────────────

REM Paste your actual keys below (replace the placeholder values)
REM Make sure your .env file exists in the project root.
REM The app reads API keys and the JioSaavn base URL from .env.

flutter run ^
  --dart-define-from-file=.env