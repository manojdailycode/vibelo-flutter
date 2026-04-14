# Quick Setup: Add Firebase Secret to GitHub

## ✅ You've Completed:
- [x] Downloaded `google-services.json` from Firebase Console
- [x] Generated the Base64 string with PowerShell
- [x] Have the Base64 string copied to clipboard

## ⏳ Next Steps (Takes 2 minutes):

### STEP 1: Go to Your Repository Settings

1. Open: https://github.com/manojdailycode/vibelo
2. Click the **Settings** tab (top right)
3. Look for **"Secrets and variables"** in the left sidebar
4. Click **"Actions"**

### STEP 2: Create New Secret

1. Click the green **"New repository secret"** button
2. You'll see a form with two fields:

   **Field 1 - Name:**
   ```
   FIREBASE_CONFIG_BASE64
   ```
   (Copy-paste exactly as shown)

   **Field 2 - Secret:**
   ```
   [PASTE YOUR BASE64 STRING HERE]
   ```
   (Right-click → Paste, or Ctrl+V)

### STEP 3: Save the Secret

1. Click the **"Add secret"** button (green button at bottom)
2. You'll see a success message: ✅ "Secret created"
3. The secret now appears in your list

## 🎯 What This Does

Now when you push code to GitHub:
- ✅ GitHub Actions workflow runs automatically
- ✅ It decodes your Firebase secret
- ✅ Creates the `google-services.json` file
- ✅ Builds the APK with Firebase features enabled
- ✅ Uploads APK to GitHub Releases

## 🆘 Having Trouble?

**Can't find "Secrets and variables"?**
- Make sure you're logged in as a user with **Admin** or **Maintain** role
- Try direct link: https://github.com/manojdailycode/vibelo/settings/secrets/actions

**Secret wasn't accepted?**
- The Base64 string should NOT have line breaks
- If it wrapped in PowerShell, remove all spaces/newlines

**Still stuck?**
- See full guide: [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md)
- Open an [Issue](https://github.com/manojdailycode/vibelo/issues/new?template=bug_report.md)

---

**After adding the secret, reply and I'll verify everything is working! ✅**
