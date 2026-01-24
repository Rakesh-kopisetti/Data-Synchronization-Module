import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8',
    appId: '1:123456789:web:abc123def456ghi789',
    messagingSenderId: '123456789',
    projectId: 'offline-sync-app-c40e5',
    authDomain: 'offline-sync-app-c40e5.firebaseapp.com',
    databaseURL: 'https://offline-sync-app-c40e5.firebaseio.com',
    storageBucket: 'offline-sync-app-c40e5.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8',
    appId: '1:123456789:android:abc123def456ghi789',
    messagingSenderId: '123456789',
    projectId: 'offline-sync-app-c40e5',
    databaseURL: 'https://offline-sync-app-c40e5.firebaseio.com',
    storageBucket: 'offline-sync-app-c40e5.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8',
    appId: '1:123456789:ios:abc123def456ghi789',
    messagingSenderId: '123456789',
    projectId: 'offline-sync-app-c40e5',
    databaseURL: 'https://offline-sync-app-c40e5.firebaseio.com',
    storageBucket: 'offline-sync-app-c40e5.appspot.com',
    iosBundleId: 'com.example.offlineSyncApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8Z8',
    appId: '1:123456789:ios:abc123def456ghi789',
    messagingSenderId: '123456789',
    projectId: 'offline-sync-app-c40e5',
    databaseURL: 'https://offline-sync-app-c40e5.firebaseio.com',
    storageBucket: 'offline-sync-app-c40e5.appspot.com',
    iosBundleId: 'com.example.offlineSyncApp',
  );
}
