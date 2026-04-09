import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:share_lib/share_lib.dart';

import 'features/home/home_shell.dart';
import 'theme/dopamine_theme.dart';

class DopamineApp extends StatefulWidget {
  const DopamineApp({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<DopamineApp> createState() => _DopamineAppState();
}

class _DopamineAppState extends State<DopamineApp> {
  bool _initialized = false;

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
    return MaterialApp(
      navigatorKey: widget.navigatorKey,
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
      home: _initialized
          ? const HomeShell()
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
