import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/models/asset_chart_bar.dart';
import '../../theme/dopamine_theme.dart';
import 'candlestick_chart_painter.dart';

class AssetCandleChartScreen extends StatefulWidget {
  const AssetCandleChartScreen({
    super.key,
    required this.symbol,
    required this.assetClass,
    this.title,
    this.themeId,
    this.assetName,
  });

  final String symbol;
  final String assetClass;
  final String? title;
  /// 크립토 차트 CoinGecko 매칭용(선택).
  final String? assetName;
  /// 설정 시 [fetchThemeChartBars] 로 테마 평균 추이 (심볼 일봉 무시).
  final String? themeId;

  static Future<void> open(
    BuildContext context, {
    required String symbol,
    required String assetClass,
    String? title,
    String? themeId,
    String? assetName,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AssetCandleChartScreen(
          symbol: symbol,
          assetClass: assetClass,
          title: title,
          themeId: themeId,
          assetName: assetName,
        ),
      ),
    );
  }

  @override
  State<AssetCandleChartScreen> createState() => _AssetCandleChartScreenState();
}

class _AssetCandleChartScreenState extends State<AssetCandleChartScreen> {
  static const double _chartHeight = 268;
  var _range = '3mo';
  late Future<List<AssetChartBar>> _future = _load();

  Future<List<AssetChartBar>> _load() {
    final tid = widget.themeId?.trim();
    if (tid != null && tid.isNotEmpty) {
      return DopamineApi.fetchThemeChartBars(themeId: tid, range: _range);
    }
    return DopamineApi.fetchAssetChartBars(
      symbol: widget.symbol,
      assetClass: widget.assetClass,
      range: _range,
      assetName: widget.assetName,
    );
  }

  void _onRange(String next) {
    if (next == _range) return;
    setState(() {
      _range = next;
      _future = _load();
    });
  }

  String _fmtPrice(BuildContext context, double p) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (p >= 10000) {
      return NumberFormat.compact(locale: locale).format(p);
    }
    if (p >= 100) {
      return p.toStringAsFixed(2);
    }
    if (p >= 1) {
      return p.toStringAsFixed(4);
    }
    return p.toStringAsFixed(6);
  }

  /// 축 라벨용 — `yMMMd`는 한국어에서 길어 좁은 폭에서 오버플로우 난다.
  static String _fmtAxisDate(DateTime d, String localeTag) {
    return DateFormat('yyyy.MM.dd', localeTag).format(d);
  }

  static TextStyle? _axisLabelStyle(ThemeData theme) {
    return theme.textTheme.labelSmall?.copyWith(
      color: DopamineTheme.textSecondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final title = widget.title?.trim().isNotEmpty == true
        ? widget.title!.trim()
        : l10n.assetDetailOpenChart;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
                colors: [
                  DopamineTheme.purpleTop,
                  DopamineTheme.purpleBottom,
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.symbol,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: DopamineTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: WidgetStateProperty.resolveWith((s) {
                          if (s.contains(WidgetState.selected)) {
                            return DopamineTheme.purpleBottom;
                          }
                          return DopamineTheme.textPrimary;
                        }),
                        backgroundColor: WidgetStateProperty.resolveWith((s) {
                          if (s.contains(WidgetState.selected)) {
                            return DopamineTheme.neonGreen;
                          }
                          return Colors.white.withValues(alpha: 0.08);
                        }),
                      ),
                      segments: [
                        ButtonSegment<String>(
                          value: '1mo',
                          label: Text(l10n.assetChartRange1mo),
                        ),
                        ButtonSegment<String>(
                          value: '3mo',
                          label: Text(l10n.assetChartRange3mo),
                        ),
                        ButtonSegment<String>(
                          value: '1y',
                          label: Text(l10n.assetChartRange1y),
                        ),
                      ],
                      selected: <String>{_range},
                      onSelectionChanged: (next) => _onRange(next.first),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: FutureBuilder<List<AssetChartBar>>(
                        future: _future,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DopamineTheme.neonGreen,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            final err = snapshot.error;
                            final msg = err is ApiException
                                ? err.message
                                : err.toString();
                            return Center(
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
                                    onPressed: () {
                                      setState(() => _future = _load());
                                    },
                                    child: Text(l10n.retry),
                                  ),
                                ],
                              ),
                            );
                          }
                          final bars = snapshot.data ?? const <AssetChartBar>[];
                          if (bars.isEmpty) {
                            return Center(child: Text(l10n.emptyState));
                          }

                          final minP =
                              bars.map((e) => e.l).reduce((a, b) => a < b ? a : b);
                          final maxP =
                              bars.map((e) => e.h).reduce((a, b) => a > b ? a : b);
                          final midP = (minP + maxP) / 2;
                          final first = bars.first;
                          final last = bars.last;
                          final mid = bars[bars.length ~/ 2];
                          final firstDt = DateTime.fromMillisecondsSinceEpoch(
                            first.t * 1000,
                            isUtc: true,
                          ).toLocal();
                          final midDt = DateTime.fromMillisecondsSinceEpoch(
                            mid.t * 1000,
                            isUtc: true,
                          ).toLocal();
                          final lastDt = DateTime.fromMillisecondsSinceEpoch(
                            last.t * 1000,
                            isUtc: true,
                          ).toLocal();

                          return ListView(
                            physics: const ClampingScrollPhysics(),
                            children: [
                              _GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      height: _chartHeight,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          SizedBox(
                                            width: 54,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _fmtPrice(context, maxP),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme.labelSmall
                                                      ?.copyWith(
                                                    color: DopamineTheme
                                                        .textSecondary,
                                                    fontFeatures: const [
                                                      FontFeature.tabularFigures(),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  _fmtPrice(context, midP),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme.labelSmall
                                                      ?.copyWith(
                                                    color: DopamineTheme
                                                        .textSecondary,
                                                    fontFeatures: const [
                                                      FontFeature.tabularFigures(),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  _fmtPrice(context, minP),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme.labelSmall
                                                      ?.copyWith(
                                                    color: DopamineTheme
                                                        .textSecondary,
                                                    fontFeatures: const [
                                                      FontFeature.tabularFigures(),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: CustomPaint(
                                              painter: CandlestickChartPainter(
                                                bars: bars,
                                                bullColor: DopamineTheme
                                                    .neonGreen
                                                    .withValues(alpha: 0.92),
                                                bearColor: DopamineTheme
                                                    .accentRed
                                                    .withValues(alpha: 0.95),
                                                gridColor: candleGridLineColor(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 62),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _fmtAxisDate(firstDt, localeTag),
                                              maxLines: 1,
                                              softWrap: false,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.start,
                                              style: _axisLabelStyle(theme),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              _fmtAxisDate(midDt, localeTag),
                                              maxLines: 1,
                                              softWrap: false,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: _axisLabelStyle(theme),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              _fmtAxisDate(lastDt, localeTag),
                                              maxLines: 1,
                                              softWrap: false,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.end,
                                              style: _axisLabelStyle(theme),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                widget.themeId != null &&
                                        widget.themeId!.trim().isNotEmpty
                                    ? l10n.themeDetailChartFootnote
                                    : l10n.assetChartFootnote,
                                softWrap: true,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: DopamineTheme.textSecondary
                                      .withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
