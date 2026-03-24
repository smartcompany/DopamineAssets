import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import 'app.dart';
import 'auth/dopamine_auth_service.dart';
import 'auth/dopamine_user.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hot restart 시 Dart [Firebase.apps]는 비었는데 네이티브에는 [DEFAULT]가 남는 경우가 있어
  // isEmpty 만으로는 duplicate-app 이 난다. 콘솔 설정 문제가 아님.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
  final authService = DopamineAuthService();
  final authProvider = AuthProvider<DopamineUser>(
    authService: authService,
  );
  await authProvider.initialize();
  runApp(
    ChangeNotifierProvider<AuthProvider<DopamineUser>>.value(
      value: authProvider,
      child: const DopamineApp(),
    ),
  );
}
