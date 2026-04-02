import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/dopamine_community_profile_gate.dart';
import '../../core/favorites/favorites_catalog.dart';
import '../../core/translation/news_title_translator.dart';
import '../../core/navigation/home_shell_navigation.dart';
import '../../core/formatting/market_cap_display.dart';
import '../../core/formatting/percent_format.dart';
import '../../core/navigation/asset_chart_url.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/models/asset_detail.dart';
import '../../data/models/ranked_asset.dart';
import '../../theme/dopamine_theme.dart';
import '../community/community_compose_screen.dart';
import 'asset_candle_chart_screen.dart';
import 'asset_posts_section.dart';
import 'asset_news_section.dart';

class AssetDetailScreen extends StatefulWidget {
  const AssetDetailScreen({super.key, required this.rankedAsset});

  final RankedAsset rankedAsset;

  static Future<void> open(BuildContext context, RankedAsset asset) async {
    if (!context.mounted) return;
    if (asset.assetClass == null || asset.assetClass!.isEmpty) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.assetDetailMissingClass)));
      }
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AssetDetailScreen(rankedAsset: asset),
      ),
    );
  }

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  late Future<AssetDetail> _future = _load();
  bool _favoriteLoading = false;
  bool _isFavorite = false;
  bool _cryptoProfileExpanded = false;
  bool _stockProfileDescriptionExpanded = false;

  Future<AssetDetail> _load() {
    return DopamineApi.fetchAssetDetail(asset: widget.rankedAsset);
  }

  Future<void> _retry() async {
    setState(() {
      _cryptoProfileExpanded = false;
      _stockProfileDescriptionExpanded = false;
      _future = _load();
    });
  }

  @override
  void didUpdateWidget(covariant AssetDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rankedAsset.symbol != widget.rankedAsset.symbol) {
      _cryptoProfileExpanded = false;
      _stockProfileDescriptionExpanded = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _syncFavoriteState();
  }

  Future<void> _syncFavoriteState() async {
    final ac = widget.rankedAsset.assetClass;
    if (ac == null || ac.isEmpty || ac == 'theme') return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _isFavorite = false);
      return;
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() => _isFavorite = false);
      return;
    }
    try {
      final v = await DopamineApi.fetchFavoriteFavored(
        idToken: token,
        symbol: widget.rankedAsset.symbol,
        assetClass: ac,
      );
      if (!mounted) return;
      setState(() => _isFavorite = v);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFavorite = false);
    }
  }

  Future<void> _toggleFavorite(AssetDetail d) async {
    if (_favoriteLoading) return;
    final ac = d.assetClass.trim();
    if (ac.isEmpty || ac == 'theme') return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileNotSignedIn)),
      );
      return;
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileNotSignedIn)),
      );
      return;
    }
    setState(() => _favoriteLoading = true);
    try {
      if (_isFavorite) {
        await DopamineApi.deleteFavoriteAsset(
          idToken: token,
          symbol: d.symbol,
          assetClass: ac,
        );
        if (!mounted) return;
        setState(() => _isFavorite = false);
      } else {
        await DopamineApi.upsertFavoriteAsset(
          idToken: token,
          symbol: d.symbol,
          assetClass: ac,
          name: d.name,
        );
        if (!mounted) return;
        setState(() => _isFavorite = true);
      }
      if (mounted) {
        unawaited(context.read<FavoritesCatalog>().syncFromServer());
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _favoriteLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final a = widget.rankedAsset;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [DopamineTheme.purpleTop, DopamineTheme.purpleBottom],
              ),
            ),
          ),
          FutureBuilder<AssetDetail>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DopamineTheme.neonGreen,
                  ),
                );
              }
              if (snapshot.hasError) {
                final err = snapshot.error;
                final msg = err is ApiException ? err.message : err.toString();
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: DopamineTheme.accentRed,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _retry,
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final d = snapshot.data;
              if (d == null) {
                return Center(child: Text(l10n.emptyState));
              }
              final isTheme = d.assetClass == 'theme';
              final chartUri = isTheme
                  ? null
                  : yahooChartPageUri(
                      assetClass: d.assetClass,
                      symbol: d.symbol,
                    );
              final themeIdForChart = widget.rankedAsset.themeId?.trim() ??
                  d.themeId?.trim() ??
                  '';
              final showThemeChart =
                  isTheme && themeIdForChart.isNotEmpty;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  d.name,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: DopamineTheme.textPrimary,
                                      ),
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.communityComposeTitle,
                                style: IconButton.styleFrom(
                                  foregroundColor: DopamineTheme.neonGreen
                                      .withValues(alpha: 0.95),
                                  side: BorderSide(
                                    color: DopamineTheme.neonGreen
                                        .withValues(alpha: 0.5),
                                    width: 1.25,
                                  ),
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(10),
                                ),
                                onPressed: () async {
                                  if (!await ensureCommunityIdentity(context)) {
                                    return;
                                  }
                                  if (!context.mounted) return;
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) => CommunityComposeScreen(
                                        initialSymbol: d.symbol,
                                        initialAssetClass: d.assetClass,
                                        initialDisplayName: d.name,
                                        initialThemeId: a.themeId ?? d.themeId,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_note_rounded),
                              ),
                              IconButton(
                                tooltip: l10n.assetDetailOpenCommunity,
                                style: IconButton.styleFrom(
                                  foregroundColor: DopamineTheme.neonGreen
                                      .withValues(alpha: 0.95),
                                  side: BorderSide(
                                    color: DopamineTheme.neonGreen
                                        .withValues(alpha: 0.5),
                                    width: 1.25,
                                  ),
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(10),
                                ),
                                onPressed: () {
                                  context
                                      .read<HomeShellNavigation>()
                                      .openCommunityForAsset(
                                        symbol: d.symbol,
                                        assetClass: d.assetClass,
                                        displayName: d.name,
                                      );
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.forum_rounded),
                              ),
                              if (chartUri != null || showThemeChart)
                                IconButton(
                                  tooltip: l10n.assetDetailOpenChart,
                                  style: IconButton.styleFrom(
                                    foregroundColor: DopamineTheme.neonGreen
                                        .withValues(alpha: 0.95),
                                    side: BorderSide(
                                      color: DopamineTheme.neonGreen
                                          .withValues(alpha: 0.5),
                                      width: 1.25,
                                    ),
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(10),
                                  ),
                                  onPressed: () {
                                    if (showThemeChart) {
                                      AssetCandleChartScreen.open(
                                        context,
                                        symbol: d.name,
                                        assetClass: d.assetClass,
                                        title: l10n.themeDetailChartTitle,
                                        themeId: themeIdForChart,
                                      );
                                    } else {
                                      AssetCandleChartScreen.open(
                                        context,
                                        symbol: d.symbol,
                                        assetClass: d.assetClass,
                                        title: l10n.assetDetailOpenChart,
                                        assetName: d.name,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.bar_chart_rounded),
                                ),
                            ],
                          ),
                          if (d.assetClass != 'theme')
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                tooltip: _isFavorite ? '관심 자산 해제' : '관심 자산 추가',
                                style: IconButton.styleFrom(
                                  foregroundColor: _isFavorite
                                      ? DopamineTheme.neonGreen
                                      : DopamineTheme.textSecondary,
                                  side: BorderSide(
                                    color: (_isFavorite
                                            ? DopamineTheme.neonGreen
                                            : DopamineTheme.textSecondary)
                                        .withValues(alpha: 0.5),
                                    width: 1.25,
                                  ),
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(10),
                                ),
                                onPressed: _favoriteLoading
                                    ? null
                                    : () => _toggleFavorite(d),
                                icon: _favoriteLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        _isFavorite
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                      ),
                              ),
                            ),
                          if (!isTheme) ...[
                            const SizedBox(height: 6),
                            Text(
                              d.symbol,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: DopamineTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ] else
                            const SizedBox(height: 14),
                          _kvRow(
                            theme,
                            l10n.assetDetailPriceChange,
                            PercentFormat.signedPercent(
                              a.priceChangePct,
                              locale,
                            ),
                          ),
                          _kvRow(
                            theme,
                            isTheme
                                ? l10n.themeScore
                                : l10n.dopamineScoreLabel,
                            a.dopamineScore.toStringAsFixed(1),
                          ),
                        ],
                      ),
                    ),
                    if (d.moveSummaryKo != null &&
                        d.moveSummaryKo!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.assetDetailMoveSummary,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: DopamineTheme.neonGreen,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              d.moveSummaryKo!.trim(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: DopamineTheme.textPrimary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.assetDetailMoveSummaryDisclaimer,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: DopamineTheme.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_shouldShowAssetProfileSection(d)) ...[
                      const SizedBox(height: 14),
                      _GlassCard(
                        child: _isCryptoAssetDetail(d)
                            ? _buildCryptoProfileBody(theme, l10n, d)
                            : _buildNonCryptoProfileBody(theme, l10n, d),
                      ),
                    ],
                    AssetNewsSection(
                      assetClass: isTheme ? 'us_stock' : d.assetClass,
                      symbol: d.symbol,
                      name: d.name,
                      uiLocaleName: l10n.localeName,
                      themeSymbols: isTheme
                          ? (a.themeSymbols ?? d.themeSymbols)
                          : null,
                    ),
                    AssetPostsSection(
                      symbol: d.symbol,
                      assetClass: d.assetClass,
                      displayName: d.name,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNonCryptoProfileBody(
    ThemeData theme,
    AppLocalizations l10n,
    AssetDetail d,
  ) {
    final desc = d.description?.trim() ?? '';
    final site = d.website?.trim() ?? '';
    final hasDesc = desc.isNotEmpty;
    final hasExtra = hasDesc || site.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.assetDetailSectionProfile,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: DopamineTheme.neonGreen,
          ),
        ),
        const SizedBox(height: 12),
        _kvMarketCapRow(theme, l10n, d),
        _kvRow(
          theme,
          l10n.assetDetailSector,
          _orDash(d.sector, l10n),
        ),
        _kvRow(
          theme,
          l10n.assetDetailIndustry,
          _orDash(d.industry, l10n),
        ),
        _kvRow(
          theme,
          l10n.assetDetailExchange,
          _orDash(d.exchange, l10n),
        ),
        if (d.baseCurrency != null && d.quoteCurrency != null)
          _kvRow(
            theme,
            l10n.assetDetailPair,
            '${d.baseCurrency} / ${d.quoteCurrency}',
          ),
        if (hasExtra) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              onTap: () {
                setState(
                  () => _stockProfileDescriptionExpanded =
                      !_stockProfileDescriptionExpanded,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _stockProfileDescriptionExpanded
                          ? l10n.assetDetailNewsShowLess
                          : l10n.assetDetailNewsShowMore,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: DopamineTheme.neonGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _stockProfileDescriptionExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: DopamineTheme.neonGreen,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (_stockProfileDescriptionExpanded && hasExtra) ...[
          const SizedBox(height: 8),
          if (hasDesc) ...[
            Text(
              l10n.assetDetailAbout,
              style: theme.textTheme.labelSmall?.copyWith(
                color: DopamineTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              key: ValueKey(
                'about|${d.symbol}|${l10n.localeName}|${desc.hashCode}',
              ),
              future: translateTextForAppLocale(desc, l10n.localeName),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DopamineTheme.neonGreen,
                        ),
                      ),
                    ),
                  );
                }
                final text = snapshot.data ?? desc;
                return Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: DopamineTheme.textPrimary,
                    height: 1.45,
                  ),
                );
              },
            ),
            if (site.isNotEmpty) const SizedBox(height: 14),
          ],
          if (site.isNotEmpty)
            InkWell(
              onTap: () => _openWebsite(site),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      color: DopamineTheme.neonGreen,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.assetDetailWebsite,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: DopamineTheme.textSecondary,
                            ),
                          ),
                          Text(
                            site,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: DopamineTheme.neonGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: DopamineTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildCryptoProfileBody(
    ThemeData theme,
    AppLocalizations l10n,
    AssetDetail d,
  ) {
    final desc = d.description?.trim() ?? '';
    final site = d.website?.trim() ?? '';
    final hasExtra = desc.isNotEmpty || site.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.assetDetailSectionProfile,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: DopamineTheme.neonGreen,
          ),
        ),
        const SizedBox(height: 12),
        _kvMarketCapRow(theme, l10n, d),
        _kvRow(
          theme,
          l10n.assetDetailMarketCapRank,
          d.marketCapRank != null
              ? '#${d.marketCapRank}'
              : l10n.assetDetailNotAvailable,
        ),
        _kvRow(
          theme,
          l10n.assetDetailCurrentPrice,
          _orDash(d.currentPrice, l10n),
        ),
        if (hasExtra) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              onTap: () {
                setState(
                  () => _cryptoProfileExpanded = !_cryptoProfileExpanded,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _cryptoProfileExpanded
                          ? l10n.assetDetailNewsShowLess
                          : l10n.assetDetailNewsShowMore,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: DopamineTheme.neonGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _cryptoProfileExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: DopamineTheme.neonGreen,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (_cryptoProfileExpanded && hasExtra) ...[
          const SizedBox(height: 8),
          if (desc.isNotEmpty) ...[
            Text(
              l10n.assetDetailAbout,
              style: theme.textTheme.labelSmall?.copyWith(
                color: DopamineTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DopamineTheme.textPrimary,
                height: 1.45,
              ),
            ),
            if (site.isNotEmpty) const SizedBox(height: 14),
          ],
          if (site.isNotEmpty)
            InkWell(
              onTap: () => _openWebsite(site),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      color: DopamineTheme.neonGreen,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.assetDetailWebsite,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: DopamineTheme.textSecondary,
                            ),
                          ),
                          Text(
                            site,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: DopamineTheme.neonGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: DopamineTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  String _orDash(String? v, AppLocalizations l10n) {
    if (v == null || v.trim().isEmpty) return l10n.assetDetailNotAvailable;
    return v;
  }

  Widget _kvRow(ThemeData theme, String label, String value) {
    return _kvRowValue(
      theme,
      label,
      Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: DopamineTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _kvRowValue(ThemeData theme, String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: DopamineTheme.textSecondary,
              ),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  Widget _kvMarketCapRow(
    ThemeData theme,
    AppLocalizations l10n,
    AssetDetail d,
  ) {
    final mainStyle = theme.textTheme.bodyMedium?.copyWith(
          color: DopamineTheme.textPrimary,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle();
    final unitStyle = theme.textTheme.bodyMedium?.copyWith(
          color: DopamineTheme.neonGreen.withValues(alpha: 0.82),
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle();
    return _kvRowValue(
      theme,
      l10n.assetDetailMarketCap,
      Text.rich(
        TextSpan(
          children: marketCapValueSpans(
            l10n,
            mainStyle: mainStyle,
            unitStyle: unitStyle,
            marketCapFromApi: d.marketCap,
            marketCapRaw: d.marketCapRaw,
            currencyCode: d.currency,
          ),
        ),
      ),
    );
  }

  Future<void> _openWebsite(String raw) async {
    var url = raw.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final u = Uri.tryParse(url);
    if (u == null) return;
    final ok = await launchUrl(u, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.assetDetailOpenLinkFailed)));
    }
  }
}

/// CoinGecko 상세를 쓰는 암호화폐 — 하단 단독 소개/웹사이트 카드는 쓰지 않고 개요「더보기」만 사용.
bool _isCryptoAssetDetail(AssetDetail d) {
  if (d.assetClass.trim().toLowerCase() == 'crypto') return true;
  for (final s in d.dataSources) {
    if (s.startsWith('coingecko_coin:')) return true;
  }
  return false;
}

/// 주식·원자재: 시총 있을 때만. 암호화폐: 시총·시총랭킹·현재가 중 하나라도 있으면.
bool _shouldShowAssetProfileSection(AssetDetail d) {
  if (_isCryptoAssetDetail(d)) {
    final mc = d.marketCap?.trim() ?? '';
    if (mc.isNotEmpty) return true;
    if (d.marketCapRank != null) return true;
    final px = d.currentPrice?.trim() ?? '';
    if (px.isNotEmpty) return true;
    return false;
  }
  final mc = d.marketCap?.trim() ?? '';
  if (mc.isNotEmpty) return true;
  final raw = d.marketCapRaw;
  return raw != null && raw > 0;
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

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
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }
}
