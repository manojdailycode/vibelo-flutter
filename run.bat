@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  run.bat  —  Local development launcher for Vibelo
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

flutter run ^
  --dart-define=JIOSAAVN_BASE_URL=%JIOSAAVN_BASE_URL% ^
  --dart-define=YOUTUBE_API_KEY=%YOUTUBE_API_KEY%