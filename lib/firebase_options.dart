import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions not configured for Linux',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBAV-JjIMXSTSQWHZKDXnWgaVznV6107I4',
    appId: '1:620910670834:web:8072682ffdbc8ae30ff16b',
    messagingSenderId: '620910670834',
    projectId: 'desperdicio-zero-f55d6',
    authDomain: 'desperdicio-zero-f55d6.firebaseapp.com',
    storageBucket: 'desperdicio-zero-f55d6.firebasestorage.app',
    measurementId: 'G-670GB4X0BV',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBAV-JjIMXSTSQWHZKDXnWgaVznV6107I4',
    appId: '1:620910670834:web:a2ed9f3916c0ed610ff16b',
    messagingSenderId: '620910670834',
    projectId: 'desperdicio-zero-f55d6',
    authDomain: 'desperdicio-zero-f55d6.firebaseapp.com',
    storageBucket: 'desperdicio-zero-f55d6.firebasestorage.app',
    measurementId: 'G-5LXZ7C4NXB',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAHzT92k-eJySvSt7FIPL0ZhgnDiMp5wLo',
    appId: '1:620910670834:ios:875f0466d3e9983f0ff16b',
    messagingSenderId: '620910670834',
    projectId: 'desperdicio-zero-f55d6',
    storageBucket: 'desperdicio-zero-f55d6.firebasestorage.app',
    iosBundleId: 'com.example.desperdicioZero',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAHzT92k-eJySvSt7FIPL0ZhgnDiMp5wLo',
    appId: '1:620910670834:ios:875f0466d3e9983f0ff16b',
    messagingSenderId: '620910670834',
    projectId: 'desperdicio-zero-f55d6',
    storageBucket: 'desperdicio-zero-f55d6.firebasestorage.app',
    iosBundleId: 'com.example.desperdicioZero',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAfa6epiJDGeVj4x_S7UQcHYIbHegCFtio',
    appId: '1:620910670834:android:0a3463496dc356bb0ff16b',
    messagingSenderId: '620910670834',
    projectId: 'desperdicio-zero-f55d6',
    storageBucket: 'desperdicio-zero-f55d6.firebasestorage.app',
  );

}