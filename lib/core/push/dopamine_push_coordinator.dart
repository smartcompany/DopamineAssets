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

    /// ARB / [MaterialApp]과 동일 — [Localizations]가 잡힐 때까지 잠깐 대기 후에도 매 등록마다 갱신.
    for (var i = 0; i < 40; i++) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) break;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }

    String pushLocaleForServer() {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        final code = Localizations.localeOf(ctx).languageCode.toLowerCase();
        return code.startsWith('ko') ? 'ko' : 'en';
      }
      return 'en';
    }

    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      // iOS: 포그라운드에서도 시스템 배너/사운드/뱃지를 표시.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('[DopaminePush] requestPermission: $e');
    }

    /// iOS는 APNs 토큰이 잡힌 뒤에야 FCM 토큰이 안정적으로 나옵니다.
    Future<String?> resolveFcmToken() async {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (var i = 0; i < 40; i++) {
          try {
            final apns = await messaging.getAPNSToken();
            if (apns != null && apns.isNotEmpty) {
              break;
            }
          } catch (e) {
            debugPrint('[DopaminePush] getAPNSToken (wait $i): $e');
          }
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
        try {
          if ((await messaging.getAPNSToken()) == null) {
            debugPrint(
              '[DopaminePush] APNS still null after wait. Simulator: often '
              'unsupported. Device: check Push capability + APNs key in Firebase.',
            );
          }
        } catch (_) {}
      }
      try {
        return await messaging.getToken();
      } catch (e) {
        debugPrint('[DopaminePush] getToken: $e');
        return null;
      }
    }

    Future<void> registerForUser(User user) async {
      const maxAttempts = 10;
      const gap = Duration(seconds: 2);
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          final fcm = await resolveFcmToken();
          if (fcm == null || fcm.isEmpty) {
            debugPrint(
              '[DopaminePush] no FCM token yet (attempt ${attempt + 1}/$maxAttempts)',
            );
          } else {
            final idToken = await user.getIdToken();
            if (idToken == null || idToken.isEmpty) {
              debugPrint('[DopaminePush] no idToken — skip push-token API');
              return;
            }
            await DopamineApi.registerPushToken(
              idToken: idToken,
              fcmToken: fcm,
              platform: dopaminePushPlatformLabel(),
              locale: pushLocaleForServer(),
            );
            debugPrint('[DopaminePush] server push-token OK');
            return;
          }
        } catch (e) {
          debugPrint(
            '[DopaminePush] register attempt ${attempt + 1}/$maxAttempts: $e',
          );
        }
        await Future<void>.delayed(gap);
      }
      debugPrint(
        '[DopaminePush] gave up after $maxAttempts attempts — check Vercel '
        'logs / Supabase dopamine_device_push_tokens / prod env.',
      );
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
          locale: pushLocaleForServer(),
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
      if (type == 'hot_mover_discussion') {
        final sym = data['symbol']?.trim() ?? '';
        final ac = data['assetClass']?.trim() ?? '';
        final rootId = data['rootCommentId']?.trim() ?? '';
        if (sym.isNotEmpty && ac.isNotEmpty && rootId.isNotEmpty) {
          nav.openCommunityHotDiscussion(
            symbol: sym,
            assetClass: ac,
            rootCommentId: rootId,
          );
        }
      }
    }

    void handleForeground(RemoteMessage m) {
      final data = m.data;
      final type = data['type'] ?? '';
      final title = m.notification?.title ?? 'Notification';
      final body = m.notification?.body ?? '';
      debugPrint(
        '[DopaminePush][foreground] type=$type title="$title" body="$body" data=$data',
      );
    }

    FirebaseMessaging.onMessage.listen(handleForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(handleOpen);
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => handleOpen(initial));
    }
  }
}
