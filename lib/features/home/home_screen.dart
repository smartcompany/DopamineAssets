import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';

import '../../core/formatting/percent_format.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/ranking_filter_prefs.dart';
import '../../data/models/market_summary.dart';
import '../../data/models/ranked_asset.dart';
import '../../data/models/theme_item.dart';
import '../../theme/dopamine_theme.dart';

/// 캡처 기준: 퍼플 그라데이션 + 네온 그린 + 글래스 카드
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<RankedAsset>> _upFuture;
  late Future<List<RankedAsset>> _downFuture;
  late final Future<List<ThemeItem>> _hotThemesFuture =
      DopamineApi.fetchThemes('hot');
  late final Future<List<ThemeItem>> _crashedThemesFuture =
      DopamineApi.fetchThemes('crashed');
  late final Future<MarketSummary> _marketFuture =
      DopamineApi.fetchMarketSummary();

  @override
  void initState() {
    super.initState();
    final classesFuture = RankingFilterPrefs.load();
    _upFuture = classesFuture.then(
      (c) => DopamineApi.fetchRankingsUp(includeAssetClasses: c),
    );
    _downFuture = classesFuture.then(
      (c) => DopamineApi.fetchRankingsDown(includeAssetClasses: c),
    );
  }

  Future<void> _applyRankingFilter(Set<String> classes) async {
    if (!mounted) return;
    setState(() {
      _upFuture = DopamineApi.fetchRankingsUp(includeAssetClasses: classes);
      _downFuture = DopamineApi.fetchRankingsDown(includeAssetClasses: classes);
    });
  }

  Future<void> _openRankingFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final initial = await RankingFilterPrefs.load();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _RankingFilterDialog(
          initial: initial,
          l10n: l10n,
          onConfirm: (selected) async {
            await RankingFilterPrefs.save(selected);
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();
            await _applyRankingFilter(selected);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        const _PurpleGradientBackground(),
        CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        l10n.homeHeaderTitleDecorated,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: DopamineTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 48),
                          Expanded(
                            child: Text(
                              l10n.homeHeadline,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: DopamineTheme.textSecondary,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.rankingFilterTitle,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            icon: Icon(
                              Icons.filter_list_rounded,
                              color: DopamineTheme.textSecondary
                                  .withValues(alpha: 0.95),
                            ),
                            onPressed: _openRankingFilter,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _SectionTitle(
                  icon: Icons.trending_up_rounded,
                  iconColor: DopamineTheme.neonGreen,
                  title: l10n.rankingsUpTitle,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: FutureBuilder<List<RankedAsset>>(
                  future: _upFuture,
                  builder: (context, snapshot) =>
                      _buildRankedList(snapshot, l10n, theme, up: true),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _SectionTitle(
                  icon: Icons.trending_down_rounded,
                  iconColor: DopamineTheme.accentRed,
                  title: l10n.rankingsDownTitle,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: FutureBuilder<List<RankedAsset>>(
                  future: _downFuture,
                  builder: (context, snapshot) =>
                      _buildRankedList(snapshot, l10n, theme, up: false),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  l10n.sectionThemes,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: DopamineTheme.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SubsectionTitle(title: l10n.themesHotTitle),
                      const SizedBox(height: 10),
                      FutureBuilder<List<ThemeItem>>(
                        future: _hotThemesFuture,
                        builder: (context, snapshot) => _buildThemeList(
                          snapshot,
                          l10n,
                          theme,
                          up: true,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SubsectionTitle(title: l10n.themesCrashedTitle),
                      const SizedBox(height: 10),
                      FutureBuilder<List<ThemeItem>>(
                        future: _crashedThemesFuture,
                        builder: (context, snapshot) => _buildThemeList(
                          snapshot,
                          l10n,
                          theme,
                          up: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.marketSummaryTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: DopamineTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FutureBuilder<MarketSummary>(
                        future: _marketFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: DopamineTheme.neonGreen,
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text(
                              l10n.errorLoadFailed,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: DopamineTheme.accentRed,
                              ),
                            );
                          }
                          final s = snapshot.data;
                          if (s == null) {
                            return Text(l10n.emptyState);
                          }
                          return _MarketSummaryGrid(l10n: l10n, summary: s);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ],
    );
  }

  Widget _buildRankedList(
    AsyncSnapshot<List<RankedAsset>> snapshot,
    AppLocalizations l10n,
    ThemeData theme, {
    required bool up,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DopamineTheme.neonGreen,
          ),
        ),
      );
    }
    if (snapshot.hasError) {
      return _InlineError(snapshot.error.toString());
    }
    final items = snapshot.data;
    if (items == null || items.isEmpty) {
      return Text(
        l10n.emptyState,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: DopamineTheme.textSecondary,
        ),
      );
    }
    const topN = 10;
    final slice =
        items.length > topN ? items.sublist(0, topN) : items;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      children: [
        for (var i = 0; i < slice.length; i++)
          _GlassAssetRow(
            rank: i + 1,
            asset: slice[i],
            locale: locale,
            upList: up,
          ),
      ],
    );
  }

  Widget _buildThemeList(
    AsyncSnapshot<List<ThemeItem>> snapshot,
    AppLocalizations l10n,
    ThemeData theme, {
    required bool up,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DopamineTheme.neonGreen,
            ),
          ),
        ),
      );
    }
    if (snapshot.hasError) {
      return _InlineError(snapshot.error.toString());
    }
    final items = snapshot.data;
    if (items == null || items.isEmpty) {
      return Text(
        l10n.emptyState,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: DopamineTheme.textSecondary,
        ),
      );
    }
    final slice = items.length > 3 ? items.sublist(0, 3) : items;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      children: [
        for (var i = 0; i < slice.length; i++)
          _GlassThemeRow(
            rank: i + 1,
            item: slice[i],
            locale: locale,
            hotList: up,
          ),
      ],
    );
  }
}

class _RankingFilterDialog extends StatefulWidget {
  const _RankingFilterDialog({
    required this.initial,
    required this.l10n,
    required this.onConfirm,
  });

  final Set<String> initial;
  final AppLocalizations l10n;
  final Future<void> Function(Set<String> selected) onConfirm;

  @override
  State<_RankingFilterDialog> createState() => _RankingFilterDialogState();
}

class _RankingFilterDialogState extends State<_RankingFilterDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initial);
  }

  void _toggle(String key) {
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else {
        _selected.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    Widget row(String key, String label) {
      return CheckboxListTile(
        value: _selected.contains(key),
        onChanged: (_) => _toggle(key),
        title: Text(label),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      );
    }

    return AlertDialog(
      title: Text(l10n.rankingFilterTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row('us_stock', l10n.assetClassBadgeUsStock),
            row('kr_stock', l10n.assetClassBadgeKrStock),
            row('crypto', l10n.assetClassBadgeCrypto),
            row('commodity', l10n.assetClassBadgeCommodity),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.rankingFilterCancel),
        ),
        FilledButton(
          onPressed: () async {
            if (_selected.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.rankingFilterNeedOne)),
              );
              return;
            }
            await widget.onConfirm(Set<String>.from(_selected));
          },
          child: Text(l10n.rankingFilterConfirm),
        ),
      ],
    );
  }
}

class _PurpleGradientBackground extends StatelessWidget {
  const _PurpleGradientBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DopamineTheme.purpleTop,
            DopamineTheme.purpleBottom,
          ],
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  final IconData icon;
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: DopamineTheme.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}

class _SubsectionTitle extends StatelessWidget {
  const _SubsectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: DopamineTheme.textSecondary,
          ),
    );
  }
}

String? _assetClassBadgeLabel(AppLocalizations l10n, String? assetClass) {
  switch (assetClass) {
    case 'us_stock':
      return l10n.assetClassBadgeUsStock;
    case 'kr_stock':
      return l10n.assetClassBadgeKrStock;
    case 'crypto':
      return l10n.assetClassBadgeCrypto;
    case 'commodity':
      return l10n.assetClassBadgeCommodity;
    default:
      return null;
  }
}

Color _assetClassBadgeColor(String? assetClass) {
  switch (assetClass) {
    case 'crypto':
      return const Color(0xFFFFB74D);
    case 'us_stock':
      return const Color(0xFF81D4FA);
    case 'kr_stock':
      return const Color(0xFFCE93D8);
    case 'commodity':
      return const Color(0xFFFFD54F);
    default:
      return DopamineTheme.textSecondary;
  }
}

class _GlassAssetRow extends StatelessWidget {
  const _GlassAssetRow({
    required this.rank,
    required this.asset,
    required this.locale,
    required this.upList,
  });

  final int rank;
  final RankedAsset asset;
  final String locale;
  final bool upList;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final badgeLabel = _assetClassBadgeLabel(l10n, asset.assetClass);
    final assetClassColor = _assetClassBadgeColor(asset.assetClass);
    final pct = asset.priceChangePct;
    final pctColor = upList
        ? (pct >= 0 ? DopamineTheme.neonGreen : DopamineTheme.accentRed)
        : (pct <= 0 ? DopamineTheme.accentRed : DopamineTheme.neonGreen);
    final rankBadgeColor = upList ? DopamineTheme.neonGreen : DopamineTheme.accentRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rankBadgeColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: rankBadgeColor.withValues(alpha: 0.45),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    '$rank',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0A0A0A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (badgeLabel != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: assetClassColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: assetClassColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                badgeLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: assetClassColor,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              asset.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: DopamineTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        asset.symbol,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: DopamineTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      PercentFormat.signedPercent(pct, locale),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: pctColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.show_chart_rounded,
                      size: 16,
                      color: pctColor.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassThemeRow extends StatelessWidget {
  const _GlassThemeRow({
    required this.rank,
    required this.item,
    required this.locale,
    required this.hotList,
  });

  final int rank;
  final ThemeItem item;
  final String locale;
  final bool hotList;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final pct = item.avgChangePct;
    final pctColor = hotList
        ? (pct >= 0 ? DopamineTheme.neonGreen : DopamineTheme.accentRed)
        : (pct <= 0 ? DopamineTheme.accentRed : DopamineTheme.neonGreen);
    final badgeColor =
        hotList ? DopamineTheme.neonGreen : DopamineTheme.accentRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.45),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    '$rank',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0A0A0A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: DopamineTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.homeThemeStockLine(item.symbolCount),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: DopamineTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      PercentFormat.signedPercent(pct, locale),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: pctColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.show_chart_rounded,
                      size: 16,
                      color: pctColor.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketSummaryGrid extends StatelessWidget {
  const _MarketSummaryGrid({
    required this.l10n,
    required this.summary,
  });

  final AppLocalizations l10n;
  final MarketSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: l10n.kimchiPremiumLabel,
                value: summary.kimchiPremiumPct == null
                    ? l10n.notAvailable
                    : '${summary.kimchiPremiumPct!.toStringAsFixed(2)}%',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: l10n.exchangeRateLabel,
                value: summary.usdKrw == null
                    ? l10n.notAvailable
                    : summary.usdKrw!.toStringAsFixed(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.marketStatusLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: DopamineTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                summary.marketStatus ?? l10n.notAvailable,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: DopamineTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: DopamineTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: DopamineTheme.neonGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.detail);

  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        detail,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DopamineTheme.accentRed,
            ),
      ),
    );
  }
}
