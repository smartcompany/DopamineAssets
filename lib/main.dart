import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import 'app.dart';
import 'auth/dopamine_auth_service.dart';
import 'auth/dopamine_user.dart';
import 'core/feed/home_asset_suggestions.dart';
import 'core/navigation/home_shell_navigation.dart';
import 'core/profile/profile_stats_store.dart';
import 'core/push/dopamine_push_coordinator.dart';
import 'core/push/firebase_messaging_bg.dart';
import 'core/text/ugc_banned_words.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
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
    // Firebase Auth + Google: idToken 발급용 웹 클라이언트 ID (google-services.json client_type 3)
    googleServerClientId:
        '312575797891-32oqllsgnd6dcp9uhr85h9s7idsmlg6t.apps.googleusercontent.com',
  );
  await authProvider.initialize();
  await UgcBannedWords.preload();
  final navigatorKey = GlobalKey<NavigatorState>();
  if (!kIsWeb) {
    await DopaminePushCoordinator.start(navigatorKey);
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider<DopamineUser>>.value(
          value: authProvider,
        ),
        ChangeNotifierProvider<HomeShellNavigation>(
          create: (_) => HomeShellNavigation(),
        ),
        ChangeNotifierProvider<HomeAssetSuggestions>(
          create: (_) => HomeAssetSuggestions(),
        ),
        ChangeNotifierProvider<ProfileStatsStore>.value(
          value: ProfileStatsStore.instance,
        ),
      ],
      child: DopamineApp(navigatorKey: navigatorKey),
    ),
  );
}
