import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/network/dopamine_api.dart';
import '../../core/translation/news_title_translator.dart';
import '../../data/models/asset_news.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/dopamine_theme.dart';
import 'asset_news_webview_screen.dart';

const int _kNewsPreviewCount = 3;

class AssetNewsSection extends StatefulWidget {
  const AssetNewsSection({
    super.key,
    required this.assetClass,
    required this.symbol,
    required this.name,
    required this.uiLocaleName,
  });

  final String assetClass;
  final String symbol;
  final String name;
  /// [AppLocalizations.localeName] — intl/ARB와 동일 기준.
  final String uiLocaleName;

  @override
  State<AssetNewsSection> createState() => _AssetNewsSectionState();
}

class _AssetNewsSectionState extends State<AssetNewsSection> {
  late Future<AssetNewsFeed> _future = _load();
  var _newsExpanded = false;

  Future<AssetNewsFeed> _load() async {
    final feed = await DopamineApi.fetchAssetNews(
      assetClass: widget.assetClass,
      symbol: widget.symbol,
      name: widget.name,
      limit: 8,
    );
    return localizeNewsTitles(feed, widget.uiLocaleName);
  }

  Future<void> _retry() async {
    setState(() {
      _newsExpanded = false;
      _future = _load();
    });
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
        oldWidget.uiLocaleName != widget.uiLocaleName) {
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
                Text(
                  l10n.assetDetailNewsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: DopamineTheme.neonGreen,
                  ),
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
