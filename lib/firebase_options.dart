import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAmpX_HK7EosJs-o1BMcPEMbZaxKqfDeKQ',
    appId: '1:685381335530:android:516d46e13e171f419c1a93',
    messagingSenderId: '685381335530',
    projectId: 'velona-ai',
    storageBucket: 'velona-ai.firebasestorage.app',
  );
}
