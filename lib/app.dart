import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:share_lib/share_lib.dart';

import 'features/home/home_shell.dart';
import 'theme/dopamine_theme.dart';

class _RouteLogObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint(
      '[UL][route] push name=${route.settings.name} from=${previousRoute?.settings.name}',
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint(
      '[UL][route] pop name=${route.settings.name} to=${previousRoute?.settings.name}',
    );
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint(
      '[UL][route] replace old=${oldRoute?.settings.name} new=${newRoute?.settings.name}',
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class DopamineApp extends StatefulWidget {
  const DopamineApp({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<DopamineApp> createState() => _DopamineAppState();
}

class _DopamineAppState extends State<DopamineApp> {
  bool _initialized = false;
  final _routeObserver = _RouteLogObserver();
  late final GoRouter _router = GoRouter(
    navigatorKey: widget.navigatorKey,
    observers: [_routeObserver],
    redirect: (context, state) {
      final uri = state.uri;
      final scheme = uri.scheme.toLowerCase();
      debugPrint('[UL][router] redirect check uri=$uri matched=${state.matchedLocation}');
      if (scheme == 'dopamineassets') {
        // 표준 스킴: dopamineassets://communityPost?postId=<id>
        if (uri.host.toLowerCase() == 'communitypost') {
          final postId = uri.queryParameters['postId']?.trim();
          if (postId != null && postId.isNotEmpty) {
            debugPrint('[UL][router] scheme redirect communityPost postId=$postId');
            return '/communityPost?postId=$postId';
          }
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          debugPrint('[UL][router] build / uri=${state.uri}');
          return const HomeShell();
        },
      ),
      GoRoute(
        path: '/communityPost',
        builder: (_, state) {
          final postId = state.uri.queryParameters['postId'];
          debugPrint('[UL][router] build /communityPost query postId=$postId uri=${state.uri}');
          return HomeShell(initialSharedPostId: postId);
        },
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future<void> _initAsync() async {
    // share_lib / AuthProvider 가 웹에서 loginWithKakaoAccount 를 쓰려면
    // KakaoSdk.init 필수. 웹에서 생략 시 SDK 내부 late 필드 → LateInitializationError.
    KakaoSdk.init(
      nativeAppKey: 'bb1d3f08a1446fbcbe02b73dc9c2ce4f',
      javaScriptAppKey: 'edb4907cf3cf066b743ab13789fec062',
    );
    if (!mounted) return;
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Center(child: CircularProgressIndicator()),
      );
    }
    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        AuthLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: DopamineTheme.dopamine,
      themeMode: ThemeMode.dark,
    );
  }
}
