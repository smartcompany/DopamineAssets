import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../core/feed/home_asset_suggestions.dart';
import '../../core/config/api_config.dart';
import '../../core/formatting/percent_format.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/ranking_filter_prefs.dart';
import '../../data/models/market_summary.dart';
import '../../data/models/ranked_asset.dart';
import '../../data/models/theme_item.dart';
import '../../theme/dopamine_theme.dart';
import '../asset/asset_detail_screen.dart';

/// 홈 본문·섹션 제목과 동일한 좌우 여백(랭킹 카드 리스트와 정렬).
const double _kHomeGutter = 20;

/// 캡처 기준: 퍼플 그라데이션 + 네온 그린 + 글래스 카드
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _rankingTopN = 10;
  static const Duration _rankingPollInterval = Duration(seconds: 5);

  Set<String>? _rankingClasses;
  /// 화면에서 토글 중인 필터(저장·API 반영은 리로드 버튼).
  late Set<String> _pendingFilter;
  List<RankedAsset>? _upItems;
  List<RankedAsset>? _downItems;
  bool _rankingsLoading = true;

  Object? _rankingsError;
  Timer? _rankingPollTimer;
  int _rankingRequestId = 0;

  late Future<List<ThemeItem>> _hotThemesFuture;
  late Future<List<ThemeItem>> _crashedThemesFuture;
  late Future<MarketSummary> _marketFuture;
  String _themeFetchLocale = '';

  @override
  void initState() {
    super.initState();
    _pendingFilter = Set<String>.from(RankingFilterPrefs.allKeys);
    _themeFetchLocale =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _hotThemesFuture = DopamineApi.fetchThemes('hot', locale: _themeFetchLocale);
    _crashedThemesFuture =
        DopamineApi.fetchThemes('crashed', locale: _themeFetchLocale);
    _marketFuture = DopamineApi.fetchMarketSummary();
    _bootstrapRankings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == _themeFetchLocale) return;
    _themeFetchLocale = lang;
    _hotThemesFuture = DopamineApi.fetchThemes('hot', locale: lang);
    _crashedThemesFuture = DopamineApi.fetchThemes('crashed', locale: lang);
    setState(() {});
  }

  /// 랭킹 + 핫/급락 테마 + 시장 요약을 한 번에 갱신 (당겨서 새로고침·초기 부트스트랩 공통)
  Future<void> _reloadRankingsThemesMarket({
    required Future<List<ThemeItem>> hot,
    required Future<List<ThemeItem>> crashed,
    required Future<MarketSummary> market,
    bool showRankingLoadingIndicator = false,
  }) async {
    await Future.wait([
      _refreshRankings(showLoadingIndicator: showRankingLoadingIndicator),
      hot,
      crashed,
      market,
    ]);
  }

  Future<void> _pullRefreshHome() async {
    if (!mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    final hot = DopamineApi.fetchThemes('hot', locale: lang);
    final crashed = DopamineApi.fetchThemes('crashed', locale: lang);
    final market = DopamineApi.fetchMarketSummary();
    setState(() {
      _hotThemesFuture = hot;
      _crashedThemesFuture = crashed;
      _marketFuture = market;
    });
    await _reloadRankingsThemesMarket(
      hot: hot,
      crashed: crashed,
      market: market,
      showRankingLoadingIndicator: true,
    );
  }

  @override
  void dispose() {
    if (_rankingPollTimer != null) {
      debugPrint(
        '[Dopamine][rankings] ${DateTime.now().toIso8601String()} dispose → poll timer cancelled',
      );
    }
    _rankingPollTimer?.cancel();
    super.dispose();
  }

  void _logRankings(String message) {
    debugPrint(
      '[Dopamine][rankings] ${DateTime.now().toIso8601String()} $message',
    );
  }

  Future<void> _bootstrapRankings() async {
    final c = await RankingFilterPrefs.load();
    if (!mounted) return;
    setState(() {
      _rankingClasses = c;
      _pendingFilter = Set<String>.from(c);
    });
    _logRankings('initial fetch (bootstrap)');
    await _reloadRankingsThemesMarket(
      hot: _hotThemesFuture,
      crashed: _crashedThemesFuture,
      market: _marketFuture,
      showRankingLoadingIndicator: false,
    );
    if (!mounted) return;
    _scheduleRankingPoll();
  }

  void _scheduleRankingPoll() {
    _rankingPollTimer?.cancel();
    _rankingPollTimer = null;
    if (!ApiConfig.enableHomeRankingPoll) {
      _logRankings('periodic poll off (ApiConfig.enableHomeRankingPoll)');
      return;
    }
    _rankingPollTimer = Timer.periodic(_rankingPollInterval, (_) {
      _logRankings('timer tick → fetch rankings');
      _refreshRankings();
    });
    _logRankings(
      'started periodic poll every ${_rankingPollInterval.inSeconds}s',
    );
  }

  Future<void> _refreshRankings({bool showLoadingIndicator = false}) async {
    final id = ++_rankingRequestId;
    final c = _rankingClasses ?? await RankingFilterPrefs.load();
    _logRankings('request #$id start (include=${c.join(",")})');
    if (showLoadingIndicator && mounted) {
      setState(() => _rankingsLoading = true);
    }
    try {
      final results = await Future.wait([
        DopamineApi.fetchRankingsUp(includeAssetClasses: c),
        DopamineApi.fetchRankingsDown(includeAssetClasses: c),
      ]);
      if (!mounted || id != _rankingRequestId) {
        _logRankings('request #$id dropped (stale or unmounted)');
        return;
      }
      _logRankings(
        'request #$id ok → up=${results[0].length} down=${results[1].length}',
      );
      setState(() {
        _upItems = results[0];
        _downItems = results[1];
        _rankingsLoading = false;
        _rankingsError = null;
      });
      if (mounted) {
        context.read<HomeAssetSuggestions>().setFromRankings(
          results[0],
          results[1],
        );
      }
    } catch (e) {
      if (!mounted || id != _rankingRequestId) {
        _logRankings('request #$id error ignored (stale or unmounted): $e');
        return;
      }
      _logRankings('request #$id error: $e');
      setState(() {
        _rankingsError = e;
        _rankingsLoading = false;
      });
    }
  }

  bool _filterSetsEqual(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final e in a) {
      if (!b.contains(e)) return false;
    }
    return true;
  }

  bool get _filtersDirty {
    final applied = _rankingClasses;
    if (applied == null) return false;
    return !_filterSetsEqual(_pendingFilter, applied);
  }

  void _togglePendingFilter(String key) {
    setState(() {
      final next = Set<String>.from(_pendingFilter);
      if (next.contains(key)) {
        if (next.length <= 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.rankingFilterNeedOne)));
          });
          return;
        }
        next.remove(key);
      } else {
        next.add(key);
      }
      _pendingFilter = next;
    });
  }

  Future<void> _applyPendingFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final applied = _rankingClasses;
    if (applied == null) return;
    if (!_filtersDirty) return;
    final next = Set<String>.from(_pendingFilter);
    if (next.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.rankingFilterNeedOne)));
      return;
    }
    try {
      await RankingFilterPrefs.save(next);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }
    if (!mounted) return;
    setState(() {
      _rankingClasses = next;
    });
    _logRankings('filter applied → reschedule poll if enabled');
    _scheduleRankingPoll();
    await _refreshRankings(showLoadingIndicator: true);
  }

  List<RankedAsset> _topRankings(List<RankedAsset>? items) {
    if (items == null || items.isEmpty) return const [];
    return items.length > _rankingTopN ? items.sublist(0, _rankingTopN) : items;
  }

  List<Widget> _animatedRankingSlivers({
    required bool up,
    required AppLocalizations l10n,
    required ThemeData theme,
  }) {
    final items = up ? _upItems : _downItems;
    final slice = _topRankings(items);

    if (_rankingsLoading && items == null) {
      return [const SliverToBoxAdapter(child: SizedBox.shrink())];
    }

    if (_rankingsError != null && items == null) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(_kHomeGutter, 0, _kHomeGutter, 20),
            child: _InlineError(_rankingsError.toString()),
          ),
        ),
      ];
    }

    if (slice.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(_kHomeGutter, 0, _kHomeGutter, 20),
            child: Text(
              l10n.emptyState,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DopamineTheme.textSecondary,
              ),
            ),
          ),
        ),
      ];
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    final orderKey = slice.map((e) => e.symbol).join('\u241e');
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_kHomeGutter, 0, _kHomeGutter, 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Column(
              key: ValueKey<String>(orderKey),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < slice.length; i++)
                  _GlassAssetRow(
                    rank: i + 1,
                    asset: slice[i],
                    locale: locale,
                    upList: up,
                  ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(child: const _PurpleGradientBackground()),
        ),
        Positioned.fill(
          child: RefreshIndicator(
            color: DopamineTheme.neonGreen,
            onRefresh: _pullRefreshHome,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _kHomeGutter,
                        16,
                        _kHomeGutter,
                        _kHomeGutter,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(width: 48),
                              Expanded(
                                child: Center(
                                  child: _HomeBlazingTitle(
                                    text: l10n.homeHeaderTitleDecorated,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: IgnorePointer(
                                  ignoring: !_filtersDirty,
                                  child: Opacity(
                                    opacity: _filtersDirty ? 1 : 0,
                                    child: IconButton(
                                      tooltip:
                                          l10n.homeRankingApplyFiltersTooltip,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 48,
                                        minHeight: 48,
                                      ),
                                      icon: Icon(
                                        Icons.refresh_rounded,
                                        color: _rankingsLoading
                                            ? DopamineTheme.textSecondary
                                                  .withValues(alpha: 0.38)
                                            : DopamineTheme.neonGreen,
                                      ),
                                      onPressed: _rankingsLoading
                                          ? null
                                          : _applyPendingFilter,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 36,
                            width: double.infinity,
                            child: _HomeFilterScrollStrip(
                              itemCount:
                                  RankingFilterPrefs.orderedKeys.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final key =
                                    RankingFilterPrefs.orderedKeys[index];
                                final label = _assetClassBadgeLabel(
                                      l10n,
                                      key,
                                    ) ??
                                    key;
                                final selected =
                                    _pendingFilter.contains(key);
                                return _FilterToggleChip(
                                  label: label,
                                  selected: selected,
                                  onTap: () => _togglePendingFilter(key),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_kHomeGutter, 0, _kHomeGutter, 8),
                    child: _SectionTitle(
                      icon: Icons.trending_up_rounded,
                      iconColor: DopamineTheme.neonGreen,
                      title: l10n.rankingsUpTitle,
                      emphasize: true,
                    ),
                  ),
                ),
                if (_rankingsLoading && _upItems == null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(_kHomeGutter, 0, _kHomeGutter, 10),
                      child: const _HomeSectionProgressLine(),
                    ),
                  ),
                ..._animatedRankingSlivers(up: true, l10n: l10n, theme: theme),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_kHomeGutter, 0, _kHomeGutter, 8),
                    child: _SectionTitle(
                      icon: Icons.trending_down_rounded,
                      iconColor: DopamineTheme.accentRed,
                      title: l10n.rankingsDownTitle,
                    ),
                  ),
                ),
                if (_rankingsLoading && _downItems == null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(_kHomeGutter, 0, _kHomeGutter, 10),
                      child: const _HomeSectionProgressLine(),
                    ),
                  ),
                ..._animatedRankingSlivers(up: false, l10n: l10n, theme: theme),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_kHomeGutter, 0, _kHomeGutter, 8),
                    child: _SectionTitle(
                      icon: Icons.hub_rounded,
                      iconColor: DopamineTheme.purpleTop,
                      title: l10n.sectionThemes,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FutureBuilder<List<ThemeItem>>(
                    future: _hotThemesFuture,
                    builder: (context, hotSnap) {
                      return FutureBuilder<List<ThemeItem>>(
                        future: _crashedThemesFuture,
                        builder: (context, crashSnap) {
                          final hotWait =
                              hotSnap.connectionState == ConnectionState.waiting;
                          final crashWait = crashSnap.connectionState ==
                              ConnectionState.waiting;
                          if (!hotWait && !crashWait) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(_kHomeGutter, 0, _kHomeGutter, 12),
                            child: const _HomeSectionProgressLine(),
                          );
                        },
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_kHomeGutter, 0, _kHomeGutter, 20),
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
                    padding: const EdgeInsets.fromLTRB(_kHomeGutter, 0, _kHomeGutter, 20),
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
                                return const SizedBox(height: 12);
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
          ),
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
      return const SizedBox(height: 10);
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

/// 가로 스크롤 필터 — 양끝이 잘릴 때만 `ShaderMask`로 살짝 페이드.
class _HomeFilterScrollStrip extends StatefulWidget {
  const _HomeFilterScrollStrip({
    required this.itemCount,
    required this.separatorBuilder,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) separatorBuilder;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  State<_HomeFilterScrollStrip> createState() =>
      _HomeFilterScrollStripState();
}

class _HomeFilterScrollStripState extends State<_HomeFilterScrollStrip> {
  final ScrollController _controller = ScrollController();
  bool _canScroll = false;
  bool _leftFade = false;
  bool _rightFade = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncEdgeFades);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncEdgeFades());
  }

  @override
  void didUpdateWidget(_HomeFilterScrollStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncEdgeFades());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncEdgeFades);
    _controller.dispose();
    super.dispose();
  }

  void _syncEdgeFades() {
    if (!mounted) return;
    if (!_controller.hasClients) return;
    final p = _controller.position;
    final max = p.maxScrollExtent;
    final px = p.pixels;
    final canScroll = max > 2;
    final left = canScroll && px > 2;
    final right = canScroll && px < max - 2;
    if (canScroll != _canScroll || left != _leftFade || right != _rightFade) {
      setState(() {
        _canScroll = canScroll;
        _leftFade = left;
        _rightFade = right;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) => ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                _leftFade ? const Color(0x00000000) : const Color(0xFFFFFFFF),
                _leftFade ? const Color(0x99FFFFFF) : const Color(0xFFFFFFFF),
                const Color(0xFFFFFFFF),
                const Color(0xFFFFFFFF),
                _rightFade ? const Color(0x99FFFFFF) : const Color(0xFFFFFFFF),
                _rightFade ? const Color(0x00000000) : const Color(0xFFFFFFFF),
              ],
              stops: const [0.0, 0.045, 0.09, 0.91, 0.955, 1.0],
            ).createShader(bounds);
          },
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: _canScroll
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.itemCount; i++) ...[
                    if (i > 0) widget.separatorBuilder(context, i - 1),
                    widget.itemBuilder(context, i),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterToggleChip extends StatelessWidget {
  const _FilterToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 30,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? DopamineTheme.neonGreen.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? DopamineTheme.neonGreen.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.22),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.0,
              letterSpacing: -0.1,
              color: selected
                  ? const Color(0xFF0A0A0A)
                  : DopamineTheme.textSecondary,
            ),
          ),
        ),
      ),
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
          colors: [DopamineTheme.purpleTop, DopamineTheme.purpleBottom],
        ),
      ),
    );
  }
}

/// 섹션 제목(상승·하락·테마) 바로 아래 로딩 라인
class _HomeSectionProgressLine extends StatelessWidget {
  const _HomeSectionProgressLine();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 3,
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        color: DopamineTheme.neonGreen,
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 상단 앱 타이틀 — 골드→오렌지 그라데이션 + 네온 글로우
class _HomeBlazingTitle extends StatelessWidget {
  const _HomeBlazingTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 27,
      height: 1.05,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.9,
    );
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: const Offset(0, 1),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: baseStyle.copyWith(
                color: const Color(0xFFFF9100).withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8E1),
              Color(0xFFFFE082),
              Color(0xFFFFCA28),
              Color(0xFFFF9100),
              Color(0xFFFF6D00),
            ],
            stops: [0.0, 0.25, 0.45, 0.72, 1.0],
          ).createShader(bounds),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: baseStyle.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.emphasize = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: emphasize ? 28 : 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style:
                (emphasize
                        ? theme.textTheme.headlineSmall
                        : theme.textTheme.titleLarge)
                    ?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: emphasize ? -0.6 : -0.3,
                      height: 1.15,
                      color: DopamineTheme.textPrimary,
                      shadows: emphasize
                          ? [
                              Shadow(
                                color: DopamineTheme.neonGreen.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 18,
                              ),
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.85),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
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
    case 'theme':
      return l10n.assetClassBadgeTheme;
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
    case 'theme':
      return DopamineTheme.neonGreen.withValues(alpha: 0.85);
    default:
      return DopamineTheme.textSecondary;
  }
}

/// 1~3위 포디엄 테두리·랭크 뱃지 그라데이션 (상승=금·은·동 톤, 하락=레드 계열)
class _PodiumStyle {
  const _PodiumStyle({
    required this.accent,
    required this.rankGradient,
    required this.rankTextColor,
  });

  final Color accent;
  final List<Color> rankGradient;
  final Color rankTextColor;

  static _PodiumStyle? forRank(int rank, bool upList) {
    if (rank < 1 || rank > 3) return null;
    if (upList) {
      switch (rank) {
        case 1:
          // 금 (Gold): 따뜻한 앰버·골드 메탈릭
          return _PodiumStyle(
            accent: const Color(0xFFD4AF37),
            rankGradient: const [
              Color(0xFFFFF8E1),
              Color(0xFFFFD54F),
              Color(0xFFFFA000),
              Color(0xFFFF8F00),
            ],
            rankTextColor: const Color(0xFF2D1F0A),
          );
        case 2:
          // 은 (Silver): 쿨 그레이·스틸 메탈릭
          return _PodiumStyle(
            accent: const Color(0xFF9CA3AF),
            rankGradient: const [
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
              Color(0xFF94A3B8),
              Color(0xFF64748B),
            ],
            rankTextColor: const Color(0xFF1E293B),
          );
        case 3:
          // 동 (Bronze): 구리·브론즈 메탈릭
          return _PodiumStyle(
            accent: const Color(0xFFB87333),
            rankGradient: const [
              Color(0xFFFFE0B2),
              Color(0xFFCD7F32),
              Color(0xFF8D5524),
              Color(0xFF5D3A1A),
            ],
            rankTextColor: const Color(0xFF1F1408),
          );
      }
    } else {
      switch (rank) {
        case 1:
          return _PodiumStyle(
            accent: const Color(0xFFFF1744),
            rankGradient: const [
              Color(0xFFFF8A80),
              Color(0xFFFF5252),
              Color(0xFFD50000),
            ],
            rankTextColor: const Color(0xFF1A0000),
          );
        case 2:
          return _PodiumStyle(
            accent: const Color(0xFFFF5252),
            rankGradient: const [
              Color(0xFFFFCDD2),
              Color(0xFFFF8A80),
              Color(0xFFE53935),
            ],
            rankTextColor: const Color(0xFF1A0000),
          );
        case 3:
          return _PodiumStyle(
            accent: const Color(0xFFFF8A80),
            rankGradient: const [
              Color(0xFFFFE0E0),
              Color(0xFFFFAB91),
              Color(0xFFE64A19),
            ],
            rankTextColor: const Color(0xFF3E2723),
          );
      }
    }
    return null;
  }
}

/// 1위 카드: 테두리·글로우가 부드럽게 맥동하는 애니메이션
class _FirstPlacePulsingShell extends StatefulWidget {
  const _FirstPlacePulsingShell({
    required this.borderRadius,
    required this.blurSigma,
    required this.podium,
    required this.child,
  });

  final double borderRadius;
  final double blurSigma;
  final _PodiumStyle podium;
  final Widget child;

  @override
  State<_FirstPlacePulsingShell> createState() =>
      _FirstPlacePulsingShellState();
}

class _FirstPlacePulsingShellState extends State<_FirstPlacePulsingShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.podium.accent;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurSigma,
          sigmaY: widget.blurSigma,
        ),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final t = _pulse.value;
            final borderColor = Color.lerp(
              accent.withValues(alpha: 0.72),
              accent.withValues(alpha: 1.0),
              t,
            )!;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42 + 0.04 * t),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(color: borderColor, width: 2.3 + 1.1 * t),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.32 + 0.28 * t),
                    blurRadius: 16 + 24 * t,
                    spreadRadius: 0.5 + 2.5 * t,
                  ),
                  BoxShadow(
                    color: accent.withValues(alpha: 0.14 + 0.22 * t),
                    blurRadius: 32 + 20 * t,
                    spreadRadius: -1,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.06 + 0.14 * t),
                    blurRadius: 10 + 12 * t,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
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
    final defaultRankColor = upList
        ? DopamineTheme.neonGreen
        : DopamineTheme.accentRed;

    final podium = _PodiumStyle.forRank(rank, upList);
    final isPodium = podium != null;
    final borderRadius = isPodium ? 18.0 : 16.0;
    final blurSigma = isPodium ? 16.0 : 14.0;

    final nameStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: DopamineTheme.textPrimary,
    );

    final pctStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w900,
      color: pctColor,
      letterSpacing: -0.3,
    );

    final symStyle = theme.textTheme.bodySmall?.copyWith(
      color: DopamineTheme.textSecondary,
    );

    final isFirstPlace = rank == 1 && podium != null;

    final rankingRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isPodium
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: podium.rankGradient,
                  )
                : null,
            color: isPodium ? null : defaultRankColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (isPodium ? podium.accent : defaultRankColor).withValues(
                  alpha: 0.55,
                ),
                blurRadius: 10,
              ),
            ],
          ),
          child: Text(
            '$rank',
            style: theme.textTheme.titleLarge?.copyWith(
              color: isPodium ? podium.rankTextColor : const Color(0xFF0A0A0A),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
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
                  Expanded(child: Text(asset.name, style: nameStyle)),
                ],
              ),
              const SizedBox(height: 4),
              Text(asset.symbol, style: symStyle),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(PercentFormat.signedPercent(pct, locale), style: pctStyle),
            const SizedBox(height: 4),
            Icon(
              Icons.show_chart_rounded,
              size: 16,
              color: pctColor.withValues(alpha: 0.9),
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(bottom: isPodium ? 14 : 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => AssetDetailScreen.open(context, asset),
          borderRadius: BorderRadius.circular(borderRadius),
          child: isFirstPlace
              ? _FirstPlacePulsingShell(
                  borderRadius: borderRadius,
                  blurSigma: blurSigma,
                  podium: podium,
                  child: rankingRow,
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: blurSigma,
                      sigmaY: blurSigma,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isPodium ? 16 : 14,
                        vertical: isPodium ? 16 : 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: isPodium ? 0.42 : 0.35,
                        ),
                        borderRadius: BorderRadius.circular(borderRadius),
                        border: Border.all(
                          color: isPodium
                              ? podium.accent.withValues(alpha: 0.92)
                              : Colors.white.withValues(alpha: 0.12),
                          width: isPodium ? 2.5 : 1,
                        ),
                        boxShadow: isPodium
                            ? [
                                BoxShadow(
                                  color: podium.accent.withValues(alpha: 0.42),
                                  blurRadius: 22,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: podium.accent.withValues(alpha: 0.18),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: rankingRow,
                    ),
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
    final badgeColor = hotList
        ? DopamineTheme.neonGreen
        : DopamineTheme.accentRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            AssetDetailScreen.open(
              context,
              RankedAsset.fromThemeItem(item),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
        ),
      ),
    );
  }
}

class _MarketSummaryGrid extends StatelessWidget {
  const _MarketSummaryGrid({required this.l10n, required this.summary});

  final AppLocalizations l10n;
  final MarketSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final body = summary.bodyForLanguageCode(lang);
    final note = summary.attributionForLanguageCode(lang);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          body.isNotEmpty ? body : l10n.notAvailable,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: DopamineTheme.textPrimary,
          ),
        ),
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            note,
            style: theme.textTheme.labelSmall?.copyWith(
              height: 1.4,
              color: DopamineTheme.textSecondary,
            ),
          ),
        ],
      ],
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
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: DopamineTheme.accentRed),
      ),
    );
  }
}
