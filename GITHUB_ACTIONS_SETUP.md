# GitHub Actions CI/CD Setup Guide

This document explains how to configure GitHub Actions for automated APK builds with Firebase authentication.

## 📋 Prerequisites

- GitHub repository (this one!)
- Firebase project with Android app configured
- `google-services.json` file from Firebase Console

## 🔐 Setting Up Firebase Secret

### Step 1: Get Your `google-services.json`

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Project Settings → Your Apps → Select Android app
4. Download `google-services.json`

### Step 2: Encode the File (Base64)

**On Windows PowerShell:**
```powershell
$fileContent = Get-Content "path\to\google-services.json" -Raw
$base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($fileContent))
$base64 | Set-Clipboard
echo "✅ Copied to clipboard!"
```

**On macOS/Linux:**
```bash
base64 -i google-services.json | tr -d '\n' | pbcopy
# or
cat google-services.json | base64 | xclip -selection clipboard
```

### Step 3: Add GitHub Secret

1. Go to your GitHub repository
2. **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `FIREBASE_CONFIG_BASE64`
5. Value: Paste the base64 string from Step 2
6. Click **Add secret**

## ✅ How It Works

The GitHub Actions workflow (`.github/workflows/build-apk.yml`) will:

1. **On every push to `main`:**
   - Check if `FIREBASE_CONFIG_BASE64` secret exists
   - If YES: Decode it and create `android/app/google-services.json`
   - If NO: Create a placeholder config (build proceeds but Firebase features won't work)

2. **Build the APK** with the proper NDK version (27.0.12077973)

3. **Upload to GitHub Releases** as a downloadable APK

## 🧪 Testing Locally

To test the build locally with your Firebase config:

```bash
# Copy google-services.json to android/app/
cp /path/to/google-services.json android/app/

# Build APK
flutter build apk --release

# APK will be in: build/app/outputs/flutter-apk/app-release.apk
```

## ⚠️ Important Security Notes

- **NEVER commit `google-services.json`** to git — it contains API keys!
- **Always use GitHub Secrets** for sensitive credentials
- The `.gitignore` file already prevents accidental commits
- Base64 encoding is NOT encryption — but combined with GitHub's secret masking, it's safe

## 🔄 Re-running Failed Builds

If the GitHub Actions build fails:

1. Check the logs in **Actions** tab
2. Fix the issue locally first
3. Commit and push — GitHub Actions will retry automatically
4. Or manually trigger: **Actions** → **Build & Release APK** → **Run workflow** → **main**

## 📦 Downloading the APK

After a successful build:

1. Go to **Releases** page
2. Find the latest `Vibelo-v1.x.x` release
3. Download the APK file
4. Install on Android device: Enable "Unknown sources" → Install

## 🆘 Troubleshooting

### Build Fails: "google-services.json is missing"
→ Add the `FIREBASE_CONFIG_BASE64` secret (see Step 3 above)

### Build Fails: "NDK version mismatch"
→ Already fixed in v1.1.0+. Make sure you're on latest `main` branch.

### APK Downloads but Firebase Features Don't Work
→ You're using the placeholder config. Add the real secret for production.

### Can't Find the Secret Setting
→ You need **Admin** or **Maintain** role in the repository

## 📞 Support

For issues:
- Check [Build Logs](https://github.com/manojdailycode/vibelo/actions)
- Open an [Issue](https://github.com/manojdailycode/vibelo/issues/new?template=bug_report.md)
- See [CONTRIBUTING.md](CONTRIBUTING.md)

---

**Once configured, APK builds automatically on every push! 🚀**
