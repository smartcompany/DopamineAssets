import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/navigation/home_shell_navigation.dart';
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

  Future<AssetDetail> _load() {
    return DopamineApi.fetchAssetDetail(asset: widget.rankedAsset);
  }

  Future<void> _retry() async {
    setState(() {
      _future = _load();
    });
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
              final chartUri = yahooChartPageUri(
                assetClass: d.assetClass,
                symbol: d.symbol,
              );
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
                                onPressed: () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) => CommunityComposeScreen(
                                        initialSymbol: d.symbol,
                                        initialAssetClass: d.assetClass,
                                        initialDisplayName: d.name,
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
                              if (chartUri != null)
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
                                    AssetCandleChartScreen.open(
                                      context,
                                      symbol: d.symbol,
                                      assetClass: d.assetClass,
                                      title: l10n.assetDetailOpenChart,
                                    );
                                  },
                                  icon: const Icon(Icons.bar_chart_rounded),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            d.symbol,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: DopamineTheme.textSecondary,
                            ),
                          ),
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
                            l10n.dopamineScoreLabel,
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
                    if (_hasAssetProfileData(d)) ...[
                      const SizedBox(height: 14),
                      _GlassCard(
                        child: Column(
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
                            _kvRow(
                              theme,
                              l10n.assetDetailMarketCap,
                              _orDash(d.marketCap, l10n),
                            ),
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
                            _kvRow(
                              theme,
                              l10n.assetDetailCurrency,
                              _orDash(d.currency, l10n),
                            ),
                            if (d.baseCurrency != null &&
                                d.quoteCurrency != null) ...[
                              _kvRow(
                                theme,
                                l10n.assetDetailPair,
                                '${d.baseCurrency} / ${d.quoteCurrency}',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    AssetNewsSection(
                      assetClass: d.assetClass,
                      symbol: d.symbol,
                      name: d.name,
                      uiLocaleName: l10n.localeName,
                    ),
                    AssetPostsSection(
                      symbol: d.symbol,
                      assetClass: d.assetClass,
                      displayName: d.name,
                    ),
                    if (d.description != null &&
                        d.description!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.assetDetailAbout,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: DopamineTheme.neonGreen,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                d.description!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: DopamineTheme.textPrimary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (d.website != null && d.website!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _GlassCard(
                          child: InkWell(
                            onTap: () => _openWebsite(d.website!),
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.link_rounded,
                                  color: DopamineTheme.neonGreen,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.assetDetailWebsite,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color:
                                                  DopamineTheme.textSecondary,
                                            ),
                                      ),
                                      Text(
                                        d.website!,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
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

  String _orDash(String? v, AppLocalizations l10n) {
    if (v == null || v.trim().isEmpty) return l10n.assetDetailNotAvailable;
    return v;
  }

  Widget _kvRow(ThemeData theme, String label, String value) {
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
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DopamineTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

bool _hasAssetProfileData(AssetDetail d) {
  bool has(String? s) => s != null && s.trim().isNotEmpty;
  if (has(d.marketCap)) return true;
  if (has(d.sector)) return true;
  if (has(d.industry)) return true;
  if (has(d.exchange)) return true;
  if (has(d.currency)) return true;
  final b = d.baseCurrency?.trim() ?? '';
  final q = d.quoteCurrency?.trim() ?? '';
  if (b.isNotEmpty && q.isNotEmpty) return true;
  return false;
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
