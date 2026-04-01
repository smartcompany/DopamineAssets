import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_lib/share_lib.dart';

import '../../core/config/api_config.dart';
import '../../core/news_ai_digest.dart';
import '../../core/network/dopamine_api.dart';
import '../../core/translation/news_title_translator.dart';
import '../../data/models/asset_news.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/dopamine_theme.dart';
import 'asset_news_webview_screen.dart';

const int _kNewsPreviewCount = 3;

bool _listEq(List<String>? a, List<String>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class AssetNewsSection extends StatefulWidget {
  const AssetNewsSection({
    super.key,
    required this.assetClass,
    required this.symbol,
    required this.name,
    required this.uiLocaleName,
    this.searchQuery,
    this.themeSymbols,
  });

  final String assetClass;
  final String symbol;
  final String name;
  /// [AppLocalizations.localeName] — intl/ARB와 동일 기준.
  final String uiLocaleName;
  /// 비어 있지 않으면 [symbol]/[name] 대신 이 문자열로 뉴스 검색 (테마명 등).
  final String? searchQuery;
  /// 테마 구성 티커 — 콤마 검색어로 뉴스 조회 (테마 상세).
  final List<String>? themeSymbols;

  @override
  State<AssetNewsSection> createState() => _AssetNewsSectionState();
}

class _AssetNewsSectionState extends State<AssetNewsSection> {
  late Future<AssetNewsFeed> _future = _load();
  var _newsExpanded = false;
  bool _summarizing = false;
  bool _adSettingsLoaded = false;

  Future<AssetNewsFeed> _load() async {
    final tickers = widget.themeSymbols
            ?.map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];
    final sq = widget.searchQuery?.trim();
    final AssetNewsFeed feed;
    if (tickers.isNotEmpty) {
      feed = await DopamineApi.fetchNewsBySearchQuery(
        q: tickers.join(','),
        assetClass: widget.assetClass,
        limit: 8,
      );
    } else if (sq != null && sq.isNotEmpty) {
      feed = await DopamineApi.fetchNewsBySearchQuery(
        q: sq,
        assetClass: widget.assetClass,
        limit: 8,
      );
    } else {
      feed = await DopamineApi.fetchAssetNews(
        assetClass: widget.assetClass,
        symbol: widget.symbol,
        name: widget.name,
        limit: 8,
      );
    }
    return localizeNewsTitles(feed, widget.uiLocaleName);
  }

  Future<void> _retry() async {
    setState(() {
      _newsExpanded = false;
      _future = _load();
    });
  }

  Future<void> _ensureAdSettings() async {
    if (_adSettingsLoaded) return;
    AdService.shared.setBaseUrl(ApiConfig.baseUrl);
    await AdService.shared.loadSettings();
    _adSettingsLoaded = true;
  }

  Future<void> _showAiSummaryDialog(NewsAiSummary summary) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: const Color(0xFF221039),
          title: Text(
            'AI 요약',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  summary.summary.isEmpty ? '요약 결과가 비어 있습니다.' : summary.summary,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 17,
                    height: 1.45,
                    color: DopamineTheme.textPrimary,
                  ),
                ),
                if (summary.impact.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '영향 포인트',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 17,
                      color: DopamineTheme.neonGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...summary.impact.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $e',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
                if (summary.risk.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '리스크',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 17,
                      color: DopamineTheme.accentRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...summary.risk.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $e',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _summarizeNewsWithAd(List<AssetNewsItem> sourceItems) async {
    if (_summarizing) return;
    setState(() {
      _summarizing = true;
    });
    try {
      await _ensureAdSettings();
      final adDone = Completer<void>();
      // showAd 의 Future 는 로드·show() 직후에 끝나며, 닫힘과 무관합니다.
      // 닫힘은 onAdDismissed / onAdFailedToShow 에서만 completer 를 완료해야 합니다.
      unawaited(
        AdService.shared.showAd(
          onAdDismissed: () {
            if (!adDone.isCompleted) adDone.complete();
          },
          onAdFailedToShow: () {
            debugPrint('[NewsAI] ad failed to show, continue summary');
            if (!adDone.isCompleted) adDone.complete();
          },
        ),
      );
      await adDone.future;
      // 전면 전환 직후 바로 다이얼로그를 띄우면 광고가 겹쳐 보일 수 있어 한 프레임 넘깁니다.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      final canonicalUrls = canonicalNewsUrlsForAi(sourceItems);
      if (canonicalUrls.isEmpty) {
        throw StateError('no news urls');
      }
      final titleDigest =
          buildNewsTitleDigestForCanonicalUrls(sourceItems, canonicalUrls);
      final result = await DopamineApi.fetchNewsAiSummary(
        urls: canonicalUrls,
        symbol: widget.symbol,
        assetClass: widget.assetClass,
        assetName: widget.name,
        locale: widget.uiLocaleName,
        titleDigest: titleDigest,
      );
      if (kDebugMode) {
        debugPrint(
          '[NewsAI][UI] symbol=${widget.symbol} '
          'cached=${result.cached} (true=DB캐시, false=OpenAI신규)',
        );
      }
      await _showAiSummaryDialog(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI 요약 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _summarizing = false;
        });
      }
    }
  }

  List<Widget> _newsBodyWidgets(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    AssetNewsFeed feed,
  ) {
    final items = feed.items;
    final hasMore = items.length > _kNewsPreviewCount;
    final visibleItems = _newsExpanded || !hasMore
        ? items
        : items.take(_kNewsPreviewCount).toList();

    if (feed.loadFailed) {
      return [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.assetDetailNewsError,
              style: theme.textTheme.bodySmall?.copyWith(
                color: DopamineTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _retry,
                child: Text(l10n.retry),
              ),
            ),
          ],
        ),
      ];
    }
    if (items.isEmpty) {
      return [
        Text(
          l10n.assetDetailNewsEmpty,
          style: theme.textTheme.bodySmall?.copyWith(
            color: DopamineTheme.textSecondary,
          ),
        ),
      ];
    }

    return [
      ...visibleItems.map(
        (item) => _NewsTile(
          item: item,
          onOpenFailed: () {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.assetDetailOpenLinkFailed),
              ),
            );
          },
        ),
      ),
      if (hasMore)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: InkWell(
            onTap: () {
              setState(() => _newsExpanded = !_newsExpanded);
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
                    _newsExpanded
                        ? l10n.assetDetailNewsShowLess
                        : l10n.assetDetailNewsShowMore,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: DopamineTheme.neonGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _newsExpanded
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
      const SizedBox(height: 10),
      Text(
        l10n.assetDetailNewsDisclaimer,
        style: theme.textTheme.labelSmall?.copyWith(
          color: DopamineTheme.textSecondary,
          height: 1.35,
        ),
      ),
    ];
  }

  @override
  void didUpdateWidget(AssetNewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetClass != widget.assetClass ||
        oldWidget.symbol != widget.symbol ||
        oldWidget.name != widget.name ||
        oldWidget.uiLocaleName != widget.uiLocaleName ||
        oldWidget.searchQuery != widget.searchQuery ||
        !_listEq(oldWidget.themeSymbols, widget.themeSymbols)) {
      setState(() {
        _newsExpanded = false;
        _future = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: FutureBuilder<AssetNewsFeed>(
        future: _future,
        builder: (context, snapshot) {
          final waiting = snapshot.connectionState == ConnectionState.waiting;
          final feed = snapshot.data;

          return _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.assetDetailNewsTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: DopamineTheme.neonGreen,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: (waiting || feed == null || feed.items.isEmpty || _summarizing)
                          ? null
                          : () => _summarizeNewsWithAd(feed.items),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: DopamineTheme.neonGreen.withValues(alpha: 0.55),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _summarizing
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.8,
                                  color: DopamineTheme.neonGreen,
                                ),
                              )
                            : Text(
                                l10n.assetDetailNewsWatchAdAiAnalysis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: DopamineTheme.neonGreen,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (waiting)
                  SizedBox(
                    height: 56,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              DopamineTheme.neonGreen.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  )
                else if (feed == null)
                  const SizedBox.shrink()
                else
                  ..._newsBodyWidgets(context, theme, l10n, feed),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({
    required this.item,
    required this.onOpenFailed,
  });

  final AssetNewsItem item;
  final VoidCallback onOpenFailed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = <String>[];
    if (item.source != null && item.source!.trim().isNotEmpty) {
      meta.add(item.source!.trim());
    }
    if (item.publishedAt != null && item.publishedAt!.trim().isNotEmpty) {
      meta.add(item.publishedAt!.trim());
    }
    final metaLine = meta.join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final u = Uri.tryParse(item.url);
            if (u == null) {
              onOpenFailed();
              return;
            }
            await AssetNewsWebViewScreen.open(
              context,
              url: u,
              pageTitle: item.title,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 20,
                  color: DopamineTheme.neonGreen.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: DopamineTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      if (metaLine.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          metaLine,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: DopamineTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: DopamineTheme.textSecondary.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
