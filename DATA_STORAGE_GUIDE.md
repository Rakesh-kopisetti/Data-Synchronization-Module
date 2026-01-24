# How to Check Where Data is Stored

## Method 1: **View Console Logs in VS Code** (Easiest)

1. Open the **Debug Console** in VS Code (View → Debug Console or Ctrl+Shift+Y)
2. Run your app:
   ```bash
   flutter run -d 22111317I
   ```
3. Look for logs like:
   ```
   🗄️ Hive Database initialized at: /data/user/0/com.example.offline_sync_app/app_flutter
   💾 Saved note: My Note to Hive at /data/user/0/com.example.offline_sync_app/app_flutter
   📂 Loaded 5 notes from Hive (/data/user/0/com.example.offline_sync_app/app_flutter)
   ```

---

## Method 2: **Use Android Studio File Explorer**

1. Open Android Studio
2. Go to **View → Tool Windows → Device Manager**
3. Select your connected device
4. Open **Device File Explorer**
5. Navigate to:
   ```
   data/user/0/com.example.offline_sync_app/app_flutter
   ```
6. You'll see the Hive database files:
   - `notes.hive` - Your notes database
   - `notes.lock` - Lock file for database

---

## Method 3: **Use ADB (Android Debug Bridge)**

Open PowerShell/Terminal and run:

```bash
# List your notes files in the app directory
adb shell ls -la /data/user/0/com.example.offline_sync_app/app_flutter

# Pull the Hive database file to your computer
adb pull /data/user/0/com.example.offline_sync_app/app_flutter/notes.hive
```

---

## Method 4: **Add Manual Logging Button in App**

I've added automatic logging. When you:
1. **Create a note** → You'll see: `💾 Saved note: [title] to Hive`
2. **Load notes** → You'll see: `📂 Loaded X notes from Hive`
3. **App starts** → You'll see: `🗄️ Hive Database initialized at: [path]`

---

## Data Storage Location on Android

### For This App:
```
/data/user/0/com.example.offline_sync_app/app_flutter/
```

### Files Created:
```
app_flutter/
├── notes.hive        ← Your notes data (binary Hive format)
└── notes.lock        ← Lock file (prevents corruption)
```

---

## What Gets Stored?

Each note contains:
```json
{
  "id": "uuid-string",
  "title": "Your note title",
  "content": "Your note content",
  "createdAt": "2026-01-24T12:30:00.000",
  "updatedAt": "2026-01-24T12:30:00.000",
  "syncStatus": "pending|synced|failed",
  "operationType": "create|update|delete",
  "isDeleted": false
}
```

---

## Check Sync Status

When you create a note offline:
1. **Locally**: Stored in Hive immediately (status: `pending`)
2. **Cloud**: Synced to Firebase when online
3. **Status**: Changes to `synced` after successful cloud upload

---

## Storage Size Limits

| Platform | Limit | Note |
|----------|-------|------|
| Android | Unlimited | Limited by device storage |
| Web | 5-10MB | Browser localStorage limit |
| iOS | Unlimited | Limited by device storage |

---

## Quick Test Steps

1. **Create a note offline**:
   - Enable Airplane Mode
   - Open app
   - Create note "Test Note"
   - Check logs: Should show `💾 Saved note: Test Note`

2. **Check storage**:
   - Open Debug Console in VS Code
   - Look for database path logs
   - Or use ADB to list files

3. **Go online & sync**:
   - Disable Airplane Mode
   - App auto-syncs
   - Check Firebase Console for the note

---

## Troubleshooting

### No logs appearing?
- Make sure you're looking at Debug Console (not Terminal)
- Run: `flutter logs` in a separate terminal
- Check that device is selected: `flutter devices`

### Can't find database file?
- Device may not have USB debugging enabled
- Try: `adb kill-server` then `adb start-server`
- Reconnect device

### Data not syncing?
- Check internet connection: Toggle Airplane Mode
- Verify Firebase is configured (see firebase_options.dart)
- Check Firebase Firestore rules allow writes

