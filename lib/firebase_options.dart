// 📁 Datei: lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAwQynDXhLoyd2gRNgJPz4F5CZlPFiRyso',
    appId: '1:824376832954:web:7a908324edea4e814f2383',
    messagingSenderId: '824376832954',
    projectId: 'gatherup-g4ther',
    authDomain: 'gatherup-g4ther.firebaseapp.com',
    databaseURL: 'https://gatherup-g4ther-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'gatherup-g4ther.firebasestorage.app',
    measurementId: 'G-2DVGZ57WJN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyAw4yvnDkhlvdy2gRNgJpZ4f5C2FIPRyso",
    authDomain: "gatherup-g4ther.firebaseapp.com",
    projectId: "gatherup-g4ther",
    storageBucket: "gatherup-g4ther.appspot.com",
    messagingSenderId: "824376832954",
    appId: "1:824376832954:web:8f0e05fad8376bc44f2383",
    databaseURL:
        "https://gatherup-g4ther-default-rtdb.europe-west1.firebasedatabase.app",
  );

  static const FirebaseOptions ios = android;
  static const FirebaseOptions macos = android;
}