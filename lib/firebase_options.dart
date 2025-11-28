import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCiht9ITkxe3f_LkZqX0AlSG1w1PRiGtHA',
    appId: '1:622512556490:android:cec09cca8978543fa46733',
    messagingSenderId: '622512556490',
    projectId: 'pos-pro-tr-2025',
    storageBucket: 'pos-pro-tr-2025.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBqRMI0rnKEzNoQjL0hJX1V3b_fOD0vpmk',
    appId: '1:622512556490:ios:7679c6451ffd2f2fa46733',
    messagingSenderId: '622512556490',
    projectId: 'pos-pro-tr-2025',
    storageBucket: 'pos-pro-tr-2025.firebasestorage.app',
    iosBundleId: 'com.example.posProTr',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDVcZcDbUskxPVAKAOEKlbcrxN6bd-l1yo',
    appId: '1:622512556490:web:c8af64db822cfa85a46733',
    messagingSenderId: '622512556490',
    projectId: 'pos-pro-tr-2025',
    authDomain: 'pos-pro-tr-2025.firebaseapp.com',
    storageBucket: 'pos-pro-tr-2025.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBqRMI0rnKEzNoQjL0hJX1V3b_fOD0vpmk',
    appId: '1:622512556490:ios:7679c6451ffd2f2fa46733',
    messagingSenderId: '622512556490',
    projectId: 'pos-pro-tr-2025',
    storageBucket: 'pos-pro-tr-2025.firebasestorage.app',
    iosBundleId: 'com.example.posProTr',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDVcZcDbUskxPVAKAOEKlbcrxN6bd-l1yo',
    appId: '1:622512556490:web:a6a2b6049c07a2f9a46733',
    messagingSenderId: '622512556490',
    projectId: 'pos-pro-tr-2025',
    authDomain: 'pos-pro-tr-2025.firebaseapp.com',
    storageBucket: 'pos-pro-tr-2025.firebasestorage.app',
  );

}