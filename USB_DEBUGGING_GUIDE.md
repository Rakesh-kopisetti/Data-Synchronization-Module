# Data Synchronization Module - Setup & Running Guide

## Project Status: ✅ COMPLETE

The offline-first data synchronization Flutter application is fully implemented with:
- ✅ Local Hive database for offline data persistence
- ✅ Firebase Firestore integration for remote sync
- ✅ Connectivity monitoring and auto-sync
- ✅ Conflict resolution logic
- ✅ Operation queuing for offline changes
- ✅ Provider-based state management
- ✅ Comprehensive tests (unit + integration)
- ✅ Full documentation in README.md

## Quick Start for USB Debugging

### 1. Prerequisites
- Flutter SDK 3.10.4+
- Android Studio with Android SDK
- USB cable
- Android device with:
  - API Level 21+ (Android 5.0+)
  - USB Debugging enabled

### 2. Enable USB Debugging on Android Device

1. Go to Settings → About Phone
2. Tap "Build Number" 7 times (until "Developer mode enabled" message)
3. Go to Settings → Developer Options
4. Enable "USB Debugging"
5. A dialog may appear asking to allow USB debugging - tap "Allow"

### 3. Connect Device and Verify Connection

```bash
cd c:\Users\RAKESH\Downloads\GPP\Data-Synchronization-Module\offline_sync_app

# List connected devices
flutter devices

# You should see:
# Android Device (mobile)     • xxxxxxxx • android-arm64  • Android XX (API XX)
```

### 4. Configure Firebase

1. Create a Firebase project at https://firebase.google.com
2. Create a Firestore database
3. Run the FlutterFire setup:
```bash
flutterfire configure --platforms=android
```

4. Update `lib/firebase_options.dart` with your Firebase credentials

### 5. Run the App on Device

```bash
flutter run
```

The app will:
1. Build for your connected Android device
2. Install on the device
3. Launch automatically
4. Display the Offline Sync Notes app

### 6. Test Offline Functionality

1. **Create Notes Offline**:
   - Airplane Mode: ON
   - App will show "Offline" status
   - Create/Edit/Delete notes
   - All changes saved locally

2. **Auto-Sync When Online**:
   - Airplane Mode: OFF
   - App automatically syncs
   - Status changes to "Online" + "Syncing..."
   - Conflicted changes resolved server-wins

3. **Monitor Sync Status**:
   - Green bar = Online & Synced
   - Red bar = Offline
   - Yellow = Syncing
   - Refresh button to manual sync

## Project Structure

```
offline_sync_app/
├── lib/
│   ├── core/constants/        # App configuration
│   ├── data/
│   │   ├── local/            # Hive database service
│   │   ├── models/           # Note model
│   │   ├── repositories/     # Local & Remote CRUD
│   │   └── unit_of_work/     # Transaction management
│   ├── domain/services/       # Sync service
│   ├── presentation/
│   │   ├── providers/        # State management
│   │   ├── screens/          # Home & Note detail
│   │   └── widgets/          # Reusable components
│   ├── firebase_options.dart
│   └── main.dart
├── test/
│   ├── unit/                 # Unit tests
│   └── integration/          # Integration tests
├── pubspec.yaml              # Dependencies
└── README.md                 # Full documentation
```

## Running Tests

```bash
# All unit tests
flutter test test/unit

# Integration tests
flutter test test/integration

# With coverage
flutter test --coverage
```

## Key Implementation Features

### Local Storage (Hive)
- Lightweight, fast local database
- Automatic schema generation
- Suitable for mobile development

### Sync Strategy
- Server-wins conflict resolution (based on updatedAt timestamp)
- Automatic operation queuing when offline
- Retry logic for failed syncs

### Architecture
- Clean Layered Architecture
- Repository Pattern (Local + Remote)
- Unit of Work Pattern for transactions
- Provider for reactive state management

### Error Handling
- Network error retry with exponential backoff
- Graceful offline degradation
- User-friendly error messages

## Troubleshooting

### Device Not Detected
```bash
# Check ADB drivers (Windows)
adb kill-server
adb start-server
flutter devices

# Or try different USB port
```

### App Crashes on Launch
```bash
# Check Firebase is configured
cat lib/firebase_options.dart

# Verify dependencies
flutter pub get
flutter pub run build_runner build
```

### Sync Not Working
- Check Firestore Security Rules allow read/write
- Verify Firebase project ID in firebase_options.dart
- Check device has internet (toggle Airplane Mode)
- Look at app logs: `flutter logs`

## Development Notes

### Adding New Fields to Note
1. Update `lib/data/models/note_model.dart`
2. Regenerate Hive adapter:
   ```bash
   flutter pub run build_runner build
   ```

### Testing Offline Sync
1. Create notes with Airplane Mode ON
2. Check local storage (Hive box)
3. Turn Airplane Mode OFF
4. Watch automatic sync occur
5. Verify in Firebase Console

### Performance Optimization
- Sync interval: 30 seconds (configurable in app_constants.dart)
- Batch operations for multiple notes
- Lazy loading in UI
- Efficient Hive queries

## File Locations

- **App Logic**: `lib/domain/services/sync_service_impl.dart`
- **Local Storage**: `lib/data/repositories/local_repository_impl.dart`
- **Remote Sync**: `lib/data/repositories/remote_repository_impl.dart`
- **UI State**: `lib/presentation/providers/`
- **Configuration**: `lib/core/constants/app_constants.dart`

## Security Considerations

1. Never commit `firebase_options.dart` with real credentials
2. Use Firebase Security Rules to protect Firestore
3. Consider adding Firebase Authentication
4. For sensitive data, implement client-side encryption

## Next Steps

1. ✅ Run on device with USB debugging
2. ✅ Test offline/online functionality
3. ✅ Create Firebase project and configure
4. ✅ Run unit and integration tests
5. ✅ Read README.md for architecture details
6. Optional: Add authentication, encryption, pagination

## Support

For detailed documentation, see `README.md` in the project root.

---

**Version**: 1.0.0
**Last Updated**: January 24, 2026
**Compatibility**: Flutter 3.10.4+, Android 5.0+ (API 21+)
