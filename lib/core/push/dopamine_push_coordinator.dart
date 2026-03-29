import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/home_shell_navigation.dart';
import '../network/dopamine_api.dart';

String dopaminePushPlatformLabel() {
  if (kIsWeb) return 'web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.android:
      return 'android';
    default:
      return 'unknown';
  }
}

/// FCM 토큰 등록·갱신 및 알림 탭 시 커뮤니티/홈 이동.
abstract final class DopaminePushCoordinator {
  DopaminePushCoordinator._();

  static Future<void> start(GlobalKey<NavigatorState> navigatorKey) async {
    if (kIsWeb) return;

    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('[DopaminePush] requestPermission: $e');
    }

    /// iOS는 APNs 토큰이 잡힌 뒤에야 FCM 토큰이 안정적으로 나옵니다. 시뮬레이터는 APNs가
    /// 영원히 null인 경우가 많아 FCM 등록이 되지 않을 수 있습니다.
    Future<String?> resolveFcmToken() async {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (var i = 0; i < 20; i++) {
          final apns = await messaging.getAPNSToken();
          if (apns != null && apns.isNotEmpty) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
        final stillNull = (await messaging.getAPNSToken()) == null;
        if (stillNull) {
          debugPrint(
            '[DopaminePush] APNS token unavailable. On iOS Simulator this is '
            'common — use a physical iPhone to register FCM, or ensure '
            'Xcode 14+ / iOS 16+ sim and Push capability + APNs key in Firebase.',
          );
        }
      }
      return messaging.getToken();
    }

    Future<void> registerForUser(User user) async {
      try {
        final fcm = await resolveFcmToken();
        if (fcm == null || fcm.isEmpty) {
          debugPrint(
            '[DopaminePush] getToken() empty — not calling /api/profile/push-token.',
          );
          return;
        }
        final idToken = await user.getIdToken();
        if (idToken == null || idToken.isEmpty) return;
        await DopamineApi.registerPushToken(
          idToken: idToken,
          fcmToken: fcm,
          platform: dopaminePushPlatformLabel(),
        );
      } catch (e) {
        debugPrint('[DopaminePush] register: $e');
      }
    }

    messaging.onTokenRefresh.listen((fcm) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || fcm.isEmpty) return;
      try {
        final idToken = await user.getIdToken();
        if (idToken == null || idToken.isEmpty) return;
        await DopamineApi.registerPushToken(
          idToken: idToken,
          fcmToken: fcm,
          platform: dopaminePushPlatformLabel(),
        );
      } catch (e) {
        debugPrint('[DopaminePush] onTokenRefresh: $e');
      }
    });

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) return;
      registerForUser(user);
    });

    final initialUser = FirebaseAuth.instance.currentUser;
    if (initialUser != null) {
      await registerForUser(initialUser);
    }

    void handleOpen(RemoteMessage m) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      final data = m.data;
      final type = data['type'] ?? '';
      final nav = Provider.of<HomeShellNavigation>(ctx, listen: false);
      if (type == 'market_daily') {
        nav.setTabIndex(0);
        return;
      }
      if (type == 'social_reply' || type == 'social_like') {
        final sym = data['symbol']?.trim() ?? '';
        final ac = data['assetClass']?.trim() ?? '';
        if (sym.isNotEmpty && ac.isNotEmpty) {
          nav.openCommunityForAsset(symbol: sym, assetClass: ac);
        }
      }
    }

    FirebaseMessaging.onMessageOpenedApp.listen(handleOpen);
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => handleOpen(initial));
    }
  }
}
