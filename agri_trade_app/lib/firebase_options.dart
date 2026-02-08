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
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDJf7e3_7se-iab9JbJCA_aJZa1nUCwOkM',
    appId: '1:3424077216:android:4460beb6faf2718a0310c5',
    messagingSenderId: '3424077216',
    projectId: 'agritradeapp-42acc',
    storageBucket: 'agritradeapp-42acc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDJf7e3_7se-iab9JbJCA_aJZa1nUCwOkM',
    appId: '1:3424077216:ios:4460beb6faf2718a0310c5',
    messagingSenderId: '3424077216',
    projectId: 'agritradeapp-42acc',
    storageBucket: 'agritradeapp-42acc.firebasestorage.app',
    iosClientId: '1:3424077216:ios:4460beb6faf2718a0310c5',
    iosBundleId: 'com.example.agriTradeApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDJf7e3_7se-iab9JbJCA_aJZa1nUCwOkM',
    appId: '1:3424077216:macos:4460beb6faf2718a0310c5',
    messagingSenderId: '3424077216',
    projectId: 'agritradeapp-42acc',
    storageBucket: 'agritradeapp-42acc.firebasestorage.app',
    iosClientId: '1:3424077216:macos:4460beb6faf2718a0310c5',
    iosBundleId: 'com.example.agriTradeApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDJf7e3_7se-iab9JbJCA_aJZa1nUCwOkM',
    appId: '1:3424077216:windows:4460beb6faf2718a0310c5',
    messagingSenderId: '3424077216',
    projectId: 'agritradeapp-42acc',
    storageBucket: 'agritradeapp-42acc.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDJf7e3_7se-iab9JbJCA_aJZa1nUCwOkM',
    appId: '1:3424077216:linux:4460beb6faf2718a0310c5',
    messagingSenderId: '3424077216',
    projectId: 'agritradeapp-42acc',
    storageBucket: 'agritradeapp-42acc.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDJf7e3_7se-iab9JbJCA_aJZa1nUCwOkM',
    appId:
        '1:3424077216:android:4460beb6faf2718a0310c5', // Replace with web app ID from Firebase Console
    messagingSenderId: '3424077216',
    projectId: 'agritradeapp-42acc',
    authDomain: 'agritradeapp-42acc.firebaseapp.com',
    storageBucket: 'agritradeapp-42acc.firebasestorage.app',
  );
}
