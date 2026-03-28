import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import '../../auth/dopamine_user.dart';
import '../../auth/present_dopamine_auth_screen.dart';
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
  List<RankedAsset>? _upItems;
  List<RankedAsset>? _downItems;
  bool _rankingsLoading = true;
  /// 필터 확인 후 새 랭킹을 받아올 때까지 상단 로딩 바 표시용
  bool _rankingsRefreshing = false;
  Object? _rankingsError;
  Timer? _rankingPollTimer;
  int _rankingRequestId = 0;

  late Future<List<ThemeItem>> _hotThemesFuture;
  late Future<List<ThemeItem>> _crashedThemesFuture;
  late Future<MarketSummary> _marketFuture;

  @override
  void initState() {
    super.initState();
    _hotThemesFuture = DopamineApi.fetchThemes('hot');
    _crashedThemesFuture = DopamineApi.fetchThemes('crashed');
    _marketFuture = DopamineApi.fetchMarketSummary();
    _bootstrapRankings();
  }

  Future<void> _pullRefreshHome() async {
    if (!mounted) return;
    setState(() {
      _hotThemesFuture = DopamineApi.fetchThemes('hot');
      _crashedThemesFuture = DopamineApi.fetchThemes('crashed');
      _marketFuture = DopamineApi.fetchMarketSummary();
    });
    await _refreshRankings();
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
    });
    _logRankings('initial fetch (bootstrap)');
    await _refreshRankings();
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

  Future<void> _refreshRankings() async {
    final id = ++_rankingRequestId;
    final c = _rankingClasses ?? await RankingFilterPrefs.load();
    _logRankings('request #$id start (include=${c.join(",")})');
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

  Future<void> _applyRankingFilter(Set<String> classes) async {
    if (!mounted) return;
    setState(() {
      _rankingClasses = classes;
      _rankingsRefreshing = true;
    });
    _logRankings('filter applied → reschedule poll if enabled');
    _scheduleRankingPoll();
    try {
      await _refreshRankings();
    } finally {
      if (mounted) {
        setState(() {
          _rankingsRefreshing = false;
        });
      }
    }
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
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: up ? DopamineTheme.neonGreen : DopamineTheme.accentRed,
              ),
            ),
          ),
        ),
      ];
    }

    if (_rankingsError != null && items == null) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _InlineError(_rankingsError.toString()),
          ),
        ),
      ];
    }

    if (slice.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
    final auth = context.watch<AuthProvider<DopamineUser>>();

    return Stack(
      fit: StackFit.expand,
      children: [
        const _PurpleGradientBackground(),
        RefreshIndicator(
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _HomeBlazingTitle(text: l10n.homeHeaderTitleDecorated),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (auth.isLoggedIn())
                            const SizedBox(width: 48)
                          else
                            IconButton(
                              tooltip: l10n.actionLogin,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              icon: Icon(
                                Icons.login_rounded,
                                color: DopamineTheme.textSecondary.withValues(
                                  alpha: 0.95,
                                ),
                              ),
                              onPressed: () =>
                                  presentDopamineAuthScreen(context),
                            ),
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
                              Icons.filter_alt_rounded,
                              color: DopamineTheme.textSecondary.withValues(
                                alpha: 0.95,
                              ),
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
            if (_rankingsRefreshing)
              SliverToBoxAdapter(
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: DopamineTheme.neonGreen,
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: _SectionTitle(
                  icon: Icons.trending_up_rounded,
                  iconColor: DopamineTheme.neonGreen,
                  title: l10n.rankingsUpTitle,
                  emphasize: true,
                ),
              ),
            ),
            ..._animatedRankingSlivers(up: true, l10n: l10n, theme: theme),
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
            ..._animatedRankingSlivers(up: false, l10n: l10n, theme: theme),
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
                        builder: (context, snapshot) =>
                            _buildThemeList(snapshot, l10n, theme, up: true),
                      ),
                      const SizedBox(height: 18),
                      _SubsectionTitle(title: l10n.themesCrashedTitle),
                      const SizedBox(height: 10),
                      FutureBuilder<List<ThemeItem>>(
                        future: _crashedThemesFuture,
                        builder: (context, snapshot) =>
                            _buildThemeList(snapshot, l10n, theme, up: false),
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
          colors: [DopamineTheme.purpleTop, DopamineTheme.purpleBottom],
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
  const _MarketSummaryGrid({required this.l10n, required this.summary});

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
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
  const _StatTile({required this.label, required this.value});

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
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: DopamineTheme.accentRed),
      ),
    );
  }
}
