import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';

import 'features/home/home_shell.dart';
import 'theme/dopamine_theme.dart';

class DopamineApp extends StatelessWidget {
  const DopamineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: DopamineTheme.dopamine,
      themeMode: ThemeMode.dark,
      home: const HomeShell(),
    );
  }
}
