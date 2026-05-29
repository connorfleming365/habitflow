# HabitFlow — Build & Install Guide
### Get your native Android app with home screen widget in 4 steps

---

## What you need
- A free GitHub account → github.com/signup
- An Android phone
- About 10 minutes

---

## Step 1 — Upload the project to GitHub

1. Go to **github.com** and sign in
2. Click the **+** button (top right) → **New repository**
3. Name it `habitflow`, set it to **Public**, click **Create repository**
4. On the next page, click **"uploading an existing file"**
5. Drag the entire `habitflow_flutter` folder into the upload area
6. Click **Commit changes**

---

## Step 2 — Build the APK automatically (free)

GitHub will now automatically build your app. Here's how to check it:

1. Click the **Actions** tab at the top of your repository
2. You'll see a workflow called **"Build HabitFlow APK"** running (yellow circle = in progress, green = done)
3. The first build takes about **5–8 minutes**
4. Once it shows a **green ✓**, click on it
5. Scroll down to **Artifacts**
6. Click **habitflow-release** to download the APK file (a `.zip` containing the APK)

---

## Step 3 — Install on your Android phone

1. On your phone, open **Settings → Security** (or Privacy on newer phones)
2. Enable **"Install from unknown sources"** or **"Allow installs from this source"**
   *(Exact wording varies by Android version — search "install unknown apps" in Settings)*
3. Transfer the APK to your phone (email it to yourself, use Google Drive, or USB)
4. Open the APK file on your phone and tap **Install**
5. Open **HabitFlow** — your habits are waiting!

---

## Step 4 — Add the home screen widget

1. Long-press on an empty area of your Android home screen
2. Tap **Widgets**
3. Scroll or search for **HabitFlow**
4. Long-press the widget and drag it to your home screen
5. Resize it to your liking (drag the corners)

The widget shows:
- Today's date
- Habits done vs. total (e.g. "2 / 5")
- A progress bar
- "All done! 🎉" when you've completed everything

The widget updates automatically when you check off habits in the app.

---

## Making changes later

Want to add a new colour, fix something, or change text?

1. Edit the relevant file on GitHub (find it in the `lib/` folder, click the pencil icon)
2. Click **Commit changes**
3. GitHub automatically rebuilds — download the new APK from Actions in 5–8 minutes

---

## Project file structure (for reference)

```
habitflow_flutter/
├── lib/
│   ├── main.dart                    ← App entry point + navigation
│   ├── theme.dart                   ← Colours & design tokens
│   ├── models/
│   │   └── habit.dart               ← Habit data model + presets
│   ├── services/
│   │   ├── storage_service.dart     ← Save/load habits & completions
│   │   ├── notification_service.dart← Daily reminders
│   │   └── widget_service.dart      ← Updates home screen widget
│   └── screens/
│       ├── today_screen.dart        ← Main check-off screen
│       ├── add_habit_screen.dart    ← Add/edit habit form
│       ├── manage_screen.dart       ← Manage habits list
│       ├── stats_screen.dart        ← Calendar + streaks
│       └── settings_screen.dart    ← Dark mode, notifications, etc.
├── android/
│   └── app/src/main/
│       ├── kotlin/.../HabitWidget.kt← Native Android widget logic
│       ├── res/layout/habit_widget.xml  ← Widget visual layout
│       ├── res/xml/habit_widget_info.xml← Widget config (min size etc.)
│       ├── res/drawable/            ← Widget background & progress bar
│       └── AndroidManifest.xml     ← App permissions & widget registration
├── .github/workflows/build.yml     ← Auto-build pipeline
└── pubspec.yaml                    ← Flutter dependencies
```

---

## Troubleshooting

**"Actions" tab shows a red ✗**
→ Click on the failed run → Click on "build" → Read the error message and share it with Claude to fix.

**APK installs but crashes on open**
→ On your phone go to Settings → Apps → HabitFlow → Permissions → enable Storage and Notifications.

**Widget shows "0 / 0" always**
→ Open the app, check off a habit, then go back to the home screen. The widget refreshes when the app is used.

**I want to publish to the Play Store**
→ You'll need a Google Play developer account ($25 one-time fee) and a signed APK. Ask Claude to help you with the signing configuration when you're ready.
