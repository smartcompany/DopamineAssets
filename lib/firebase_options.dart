// `flutterfire configure` 로 생성한 값으로 교체하세요. (플레이스홀더 상태에서는 Firebase 초기화가 실패할 수 있습니다.)
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web — run FlutterFire CLI.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA6DHvnQ0kSt1bPbrctB-KEBvOtm-_b_qA',
    appId: '1:312575797891:android:1093227bef277a711f49b6',
    messagingSenderId: '312575797891',
    projectId: 'dopamineassets',
    storageBucket: 'dopamineassets.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB8ggQswOQaVh08wX0-Nlw5CqRzNJpDbWg',
    appId: '1:312575797891:ios:c192c228de6c5ec61f49b6',
    messagingSenderId: '312575797891',
    projectId: 'dopamineassets',
    storageBucket: 'dopamineassets.firebasestorage.app',
    iosBundleId: 'com.smartcompany.dopamineAssets',
  );

}