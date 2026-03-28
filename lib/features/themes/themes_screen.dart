import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';

import '../../core/formatting/percent_format.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/models/ranked_asset.dart';
import '../../data/models/theme_item.dart';
import '../asset/asset_detail_screen.dart';
import '../../widgets/async_body.dart';

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  late Future<List<ThemeItem>> _hotFuture;
  late Future<List<ThemeItem>> _crashedFuture;
  late Future<List<ThemeItem>> _emergingFuture;
  String _locale = '';

  @override
  void initState() {
    super.initState();
    _locale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _restartThemeFutures();
  }

  void _restartThemeFutures() {
    _hotFuture = DopamineApi.fetchThemes('hot', locale: _locale);
    _crashedFuture = DopamineApi.fetchThemes('crashed', locale: _locale);
    _emergingFuture = DopamineApi.fetchThemes('emerging', locale: _locale);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == _locale) return;
    _locale = lang;
    _restartThemeFutures();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navThemes)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _ThemeSection(
            title: l10n.themesHotTitle,
            future: _hotFuture,
          ),
          _ThemeSection(
            title: l10n.themesCrashedTitle,
            future: _crashedFuture,
          ),
          _ThemeSection(
            title: l10n.themesEmergingTitle,
            future: _emergingFuture,
          ),
        ],
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  const _ThemeSection({
    required this.title,
    required this.future,
  });

  final String title;
  final Future<List<ThemeItem>> future;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium,
          ),
        ),
        FutureBuilder<List<ThemeItem>>(
          future: future,
          builder: (context, snapshot) {
            return buildAsyncBody<List<ThemeItem>>(
              context: context,
              snapshot: snapshot,
              onData: (context, items) {
                if (items.isEmpty) {
                  final l10n = AppLocalizations.of(context)!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l10n.emptyState),
                  );
                }
                return Column(
                  children: [
                    for (final item in items) _ThemeTile(item: item),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.item});

  final ThemeItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => AssetDetailScreen.open(
              context,
              RankedAsset.fromThemeItem(item),
            ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: theme.textTheme.titleMedium,
              ),
            const SizedBox(height: 6),
            Text(
              '${l10n.themeScore}: ${item.themeScore.toStringAsFixed(1)}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '${l10n.priceChangePct}: ${PercentFormat.signedPercent(item.avgChangePct, locale)}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '${l10n.volumeChangePct}: ${PercentFormat.signedPercent(item.volumeLiftPct, locale)}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '${l10n.stockCount}: ${item.symbolCount}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        ),
      ),
    );
  }
}
