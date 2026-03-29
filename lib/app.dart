import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:share_lib/share_lib.dart';

import 'features/home/home_shell.dart';
import 'theme/dopamine_theme.dart';

class DopamineApp extends StatelessWidget {
  const DopamineApp({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        AuthLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: DopamineTheme.dopamine,
      themeMode: ThemeMode.dark,
      home: const HomeShell(),
    );
  }
}
