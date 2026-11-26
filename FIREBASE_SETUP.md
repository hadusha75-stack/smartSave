# Firebase Setup Guide for SaveSmart

Follow every step in order. Each step has a tick box — check them off as you go.

---

## Step 1 — Create the Firebase project

1. Go to https://console.firebase.google.com
2. Click **Add project** → name it `savesmart` → Continue
3. Enable Google Analytics if you want usage stats (optional) → Create project

---

## Step 2 — Enable Authentication

1. In the Firebase console, open your project
2. Left sidebar → **Build → Authentication** → Get started
3. **Sign-in method** tab → **Email/Password** → Enable → Save

---

## Step 3 — Enable Cloud Firestore

1. Left sidebar → **Build → Firestore Database** → Create database
2. Choose **Start in production mode** (we will deploy rules next)
3. Location: choose **europe-west1** (Ireland) or the region closest to Ethiopia
4. Done

---

## Step 4 — Deploy Security Rules

The rules file is at `firestore.rules` in the project root.

Option A — Firebase CLI (recommended):
```
npm install -g firebase-tools
firebase login
firebase init firestore   # select your project, accept default file names
firebase deploy --only firestore:rules
```

Option B — Firebase console:
1. Firestore Database → **Rules** tab
2. Paste the contents of `firestore.rules`
3. Publish

---

## Step 5 — Enable Firebase Cloud Messaging (FCM)

1. Left sidebar → **Build → Messaging** → Get started
2. No extra configuration needed for Android/iOS at this stage

---

## Step 6 — Add your Android app

1. Left sidebar → ⚙️ **Project settings** → **Your apps** tab → Android icon
2. Android package name: `com.example.savesmart`
   (must match `applicationId` in `android/app/build.gradle.kts`)
3. App nickname: `SaveSmart Android`
4. Debug signing certificate SHA-1 (optional for now, required for Google Sign-In)
5. Click **Register app**
6. Download `google-services.json`
7. Place it at: `android/app/google-services.json`
   **Never commit this file to a public repo.**

---

## Step 7 — Run FlutterFire CLI

FlutterFire CLI generates `lib/firebase_options.dart` automatically.

```bash
# Install FlutterFire CLI (once)
dart pub global activate flutterfire_cli

# In the project root
flutterfire configure --project=savesmart
```

When prompted:
- Select Android (and iOS if you have a Mac)
- Accept the generated `lib/firebase_options.dart`

This file is safe to commit — it contains only public identifiers.

---

## Step 8 — Add Firestore indexes

Some queries need composite indexes. Run the app; whenever you see a Firestore error
in the console that includes a link like:
  `https://console.firebase.google.com/v1/r/project/.../indexes?create_composite=...`
Click that link and create the index. The most common ones for SaveSmart:

| Collection               | Fields                        | Order |
|--------------------------|-------------------------------|-------|
| users/{uid}/goals        | status ASC, createdAt DESC    | —     |
| users/{uid}/goals/{id}/transactions | date DESC        | —     |
| tips                     | createdAt DESC                | —     |
| feedback                 | status ASC, createdAt DESC    | —     |

---

## Step 9 — Test offline persistence

1. Build and run the app on a physical Android device or emulator
2. Log in and create a goal
3. Enable **Airplane mode** on the device
4. Add a saving — the UI should update immediately (Firestore offline cache)
5. Turn Airplane mode off — the saving syncs to the cloud automatically
6. You can verify in the Firestore console that the document appeared

---

## Step 10 — Build for release (Android)

```bash
flutter build apk --release
# APK location: build/app/outputs/flutter-apk/app-release.apk
```

For a bundle (required for Play Store):
```bash
flutter build appbundle --release
```

---

## Keeping secrets safe

- `google-services.json` → add to `.gitignore` ✓ (already done)
- `lib/firebase_options.dart` → safe to commit (no secrets)
- Never put API keys or passwords in Dart source code
