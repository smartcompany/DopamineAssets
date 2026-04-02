import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import '../../auth/dopamine_community_profile_gate.dart';
import '../../auth/dopamine_user.dart';
import '../../auth/present_dopamine_auth_screen.dart';
import '../../core/feed/home_asset_suggestions.dart';
import '../../core/navigation/home_shell_bottom_inset.dart';
import '../../core/navigation/home_shell_navigation.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../core/profile/profile_stats_store.dart';
import '../../data/models/community_post.dart';
import '../../data/models/ranked_asset.dart';
import '../../theme/dopamine_theme.dart';
import '../../widgets/run_with_fullscreen_loading.dart';
import '../profile/public_profile_screen.dart';
import 'community_compose_screen.dart';
import 'community_post_card.dart';
import 'community_post_detail_screen.dart';
import 'community_report_sheet.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  var _sort = 'latest';

  /// [FutureBuilder] 대신 사용: 연속 검색 시 늦게 도착한 응답이 최신 칩/쿼리를 덮어쓰지 않게 함.
  int _fetchGen = 0;
  bool _loading = true;
  Object? _fetchError;
  List<CommunityPost> _posts = const [];

  HomeShellNavigation? _nav;
  int _lastCommunityFeedEpoch = 0;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  bool _symbolFilterActive = false;
  String? _symbolFilterSymbol;
  String? _symbolFilterClass;

  final List<String> _bodySearchTerms = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleFetch();
    });
  }

  Future<void> _scheduleFetch() async {
    final gen = ++_fetchGen;
    setState(() {
      _loading = true;
      _fetchError = null;
    });
    String? idToken;
    if (mounted) {
      final auth = context.read<AuthProvider<DopamineUser>>();
      if (auth.isLoggedIn()) {
        idToken = await auth.getIdToken();
      }
    }
    try {
      final items = await DopamineApi.fetchCommunityPosts(
        sort: _sort,
        symbol: _symbolFilterActive ? _symbolFilterSymbol : null,
        assetClass: _symbolFilterActive ? _symbolFilterClass : null,
        bodyTerms: _bodySearchTerms.isEmpty
            ? null
            : List<String>.from(_bodySearchTerms),
        idToken: idToken,
      );
      if (!mounted || gen != _fetchGen) return;
      setState(() {
        _posts = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || gen != _fetchGen) return;
      setState(() {
        _fetchError = e;
        _loading = false;
      });
    }
  }

  Future<void> _openPostDetail(CommunityPost p) async {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final myUid = context.read<AuthProvider<DopamineUser>>().currentUid();
    final changed = await CommunityPostDetailScreen.open(
      context,
      post: p,
      locale: locale,
      myUid: myUid,
      onPostUpdated: (u) {
        final i = _posts.indexWhere((x) => x.id == u.id);
        if (i >= 0) {
          setState(() => _posts[i] = u);
        }
      },
    );
    if (changed && mounted) {
      _scheduleFetch();
    }
  }

  Future<void> _toggleLike(int index, CommunityPost p) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await ensureCommunityIdentity(context, showLoginHintSnack: true)) {
      return;
    }
    if (!mounted) return;
    final token = await context.read<AuthProvider<DopamineUser>>().getIdToken();
    if (token == null || token.isEmpty || !mounted) return;
    try {
      final r = await DopamineApi.toggleCommentLike(
        idToken: token,
        commentId: p.id,
      );
      if (!mounted) return;
      setState(() {
        final next = List<CommunityPost>.from(_posts);
        next[index] = p.copyWith(likeCount: r.likeCount, likedByMe: r.liked);
        _posts = next;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorLoadFailed)));
    }
  }

  Future<void> _openAuthorProfile(CommunityPost post) async {
    await PublicProfileScreen.open(
      context,
      authorUid: post.authorUid,
      authorName: post.authorDisplayName,
      authorPhotoUrl: post.authorPhotoUrl,
    );
    if (!mounted) return;
    await _scheduleFetch();
  }

  void _onSort(String next) {
    if (next == _sort) return;
    setState(() {
      _sort = next;
    });
    _scheduleFetch();
  }

  void _handleNav() {
    final nav = _nav;
    if (nav == null || !mounted) return;

    final f = nav.takePendingFilter();
    if (f != null) {
      setState(() {
        _symbolFilterActive = true;
        _symbolFilterSymbol = f.symbol;
        _symbolFilterClass = f.assetClass;
        _bodySearchTerms.clear();
        _searchController.clear();
      });
      _scheduleFetch();
    }

    if (nav.communityFeedEpoch != _lastCommunityFeedEpoch) {
      _lastCommunityFeedEpoch = nav.communityFeedEpoch;
      _scheduleFetch();
    }
  }

  void _removeSymbolFilter() {
    setState(() {
      _symbolFilterActive = false;
      _symbolFilterSymbol = null;
      _symbolFilterClass = null;
    });
    _scheduleFetch();
  }

  void _removeBodyTerm(String term) {
    setState(() {
      _bodySearchTerms.remove(term);
    });
    _scheduleFetch();
  }

  Future<void> _openCompose(BuildContext context) async {
    if (!await ensureCommunityIdentity(context)) return;
    if (!context.mounted) return;
    if (!context.read<AuthProvider<DopamineUser>>().isLoggedIn()) return;
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (ctx) => CommunityComposeScreen(
          initialSymbol: _symbolFilterActive ? _symbolFilterSymbol : null,
          initialAssetClass: _symbolFilterActive ? _symbolFilterClass : null,
        ),
      ),
    );
    if ((result == true || result is CommunityPost) && mounted) {
      _scheduleFetch();
    }
  }

  Future<void> _openEditCompose(CommunityPost p) async {
    if (!await ensureCommunityIdentity(context)) return;
    if (!mounted) return;
    if (!context.read<AuthProvider<DopamineUser>>().isLoggedIn()) return;
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => CommunityComposeScreen(editPrefill: p),
      ),
    );
    if ((result == true || result is CommunityPost) && mounted) {
      _scheduleFetch();
    }
  }

  Future<void> _reportCommunityPost(CommunityPost p) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider<DopamineUser>>();
    if (!auth.isLoggedIn()) {
      await presentDopamineAuthScreen(context);
      return;
    }
    final reasonText = await showCommunityReportSheet(context);
    if (reasonText == null || !mounted) return;
    final token = await auth.getIdToken();
    if (token == null || token.isEmpty) return;
    try {
      await DopamineApi.reportAssetComment(
        commentId: p.id,
        idToken: token,
        reason: reasonText,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.communityReportSubmitted)));
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _blockAuthorFromPost(CommunityPost p) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider<DopamineUser>>();
    if (!auth.isLoggedIn()) {
      await presentDopamineAuthScreen(context);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.communityBlockAuthorTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.communityBlockAuthorMessage(p.authorDisplayName)),
            const SizedBox(height: 10),
            Text(
              l10n.communityBlockAuthorHint,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: DopamineTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileDeleteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.communityBlockAuthorShort,
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final token = await auth.getIdToken();
    if (token == null || token.isEmpty) return;
    try {
      await DopamineApi.blockUser(idToken: token, targetUid: p.authorUid);
      if (!mounted) return;
      setState(() {
        _posts = _posts.where((x) => x.authorUid != p.authorUid).toList();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.communityUserBlocked)));
      ProfileStatsStore.instance.refreshWithCurrentFirebaseUser();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _deleteCommunityPost(CommunityPost p) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.profileActivityDeleteDialogTitle),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.profileDeleteCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l10n.profileActivityDeletePost,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    try {
      await runWithFullscreenLoading<void>(
        context,
        (() async {
          final token =
              await context.read<AuthProvider<DopamineUser>>().getIdToken();
          if (token == null || token.isEmpty) return;
          await DopamineApi.deleteAssetComment(id: p.id, idToken: token);
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.profileActivityPostDeleted)));
          _scheduleFetch();
        })(),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _submitSearch(String raw) {
    final parts = raw
        .trim()
        .split(RegExp(r'\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return;
    setState(() {
      for (final p in parts) {
        if (!_bodySearchTerms.contains(p)) {
          _bodySearchTerms.add(p);
        }
      }
      _searchController.clear();
    });
    _scheduleFetch();
  }

  String _classBadge(String assetClass, AppLocalizations l10n) {
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
        return assetClass;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<HomeShellNavigation>();
    if (!identical(_nav, nav)) {
      _nav?.removeListener(_handleNav);
      _nav = nav;
      _lastCommunityFeedEpoch = nav.communityFeedEpoch;
      _nav!.addListener(_handleNav);
    }
  }

  @override
  void dispose() {
    _nav?.removeListener(_handleNav);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final auth = context.watch<AuthProvider<DopamineUser>>();
    final myUid = auth.currentUid();
    context.watch<HomeAssetSuggestions>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!auth.isLoggedIn())
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => presentDopamineAuthScreen(context),
                  child: Text(
                    l10n.actionLogin,
                    style: const TextStyle(
                      color: DopamineTheme.neonGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_symbolFilterActive || _bodySearchTerms.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (_symbolFilterActive && _symbolFilterSymbol != null)
                          InputChip(
                            label: Text(_symbolFilterSymbol!),
                            deleteIcon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                            ),
                            onDeleted: _removeSymbolFilter,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: DopamineTheme.neonGreen.withValues(
                              alpha: 0.12,
                            ),
                            side: BorderSide.none,
                            labelStyle: theme.textTheme.labelLarge?.copyWith(
                              color: DopamineTheme.neonGreen,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        for (final term in _bodySearchTerms)
                          InputChip(
                            label: Text(term),
                            deleteIcon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                            ),
                            onDeleted: () => _removeBodyTerm(term),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            labelStyle: theme.textTheme.labelLarge?.copyWith(
                              color: DopamineTheme.textPrimary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  TapRegion(
                    groupId: 'community_search',
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                        child: RawAutocomplete<RankedAsset>(
                          textEditingController: _searchController,
                          focusNode: _searchFocusNode,
                          displayStringForOption: (RankedAsset a) => a.symbol,
                          optionsBuilder: (TextEditingValue value) {
                            final q = value.text;
                            if (q.trim().isEmpty) {
                              return const Iterable<RankedAsset>.empty();
                            }
                            return context
                                .read<HomeAssetSuggestions>()
                                .matchingAssets(q);
                          },
                          onSelected: (RankedAsset a) {
                            final ac = a.assetClass?.trim();
                            if (ac == null || ac.isEmpty) return;
                            setState(() {
                              _symbolFilterActive = true;
                              _symbolFilterSymbol = a.symbol;
                              _symbolFilterClass = ac;
                              _searchController.clear();
                            });
                            _scheduleFetch();
                          },
                          fieldViewBuilder:
                              (
                                BuildContext context,
                                TextEditingController controller,
                                FocusNode focusNode,
                                VoidCallback onFieldSubmitted,
                              ) {
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  groupId: 'community_search',
                                  onTapOutside: (_) => focusNode.unfocus(),
                                  textInputAction: TextInputAction.search,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: DopamineTheme.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        Icons.search_rounded,
                                        color: DopamineTheme.textSecondary
                                            .withValues(alpha: 0.9),
                                        size: 22,
                                      ),
                                      onPressed: () =>
                                          _submitSearch(_searchController.text),
                                    ),
                                    suffixIconConstraints: const BoxConstraints(
                                      minWidth: 44,
                                      minHeight: 44,
                                    ),
                                  ),
                                  onSubmitted: (v) {
                                    onFieldSubmitted();
                                    _submitSearch(v);
                                  },
                                );
                              },
                          optionsViewBuilder:
                              (
                                BuildContext context,
                                void Function(RankedAsset) onSelected,
                                Iterable<RankedAsset> options,
                              ) {
                                final list = options.toList();
                                if (list.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return TapRegion(
                                  groupId: 'community_search',
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 8,
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(0xFF1A1525),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 240,
                                        ),
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          padding: EdgeInsets.zero,
                                          itemCount: list.length,
                                          separatorBuilder: (_, _) => Divider(
                                            height: 1,
                                            color: Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                          ),
                                          itemBuilder: (context, i) {
                                            final a = list[i];
                                            final ac = a.assetClass;
                                            return ListTile(
                                              dense: true,
                                              title: Text(
                                                a.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: DopamineTheme
                                                          .textPrimary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              subtitle: Text(
                                                ac != null
                                                    ? '${a.symbol} · ${_classBadge(ac, l10n)}'
                                                    : a.symbol,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: DopamineTheme
                                                          .textSecondary,
                                                    ),
                                              ),
                                              onTap: () => onSelected(a),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IntrinsicWidth(
                    child: SegmentedButton<String>(
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
                          value: 'latest',
                          label: Text(l10n.communitySortLatest),
                        ),
                        ButtonSegment<String>(
                          value: 'popular',
                          label: Text(l10n.communitySortPopular),
                        ),
                      ],
                      selected: <String>{_sort},
                      onSelectionChanged: (s) => _onSort(s.first),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _openCompose(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: DopamineTheme.neonGreen,
                      foregroundColor: const Color(0xFF0A0A0A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    label: Text(
                      l10n.communityWrite,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: DopamineTheme.neonGreen,
                onRefresh: _scheduleFetch,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final minScrollExtent = constraints.maxHeight > 0
                        ? constraints.maxHeight
                        : 400.0;
                    if (_loading) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: minScrollExtent,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DopamineTheme.neonGreen,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    if (_fetchError != null) {
                      final err = _fetchError!;
                      final msg = err is ApiException
                          ? err.message
                          : err.toString();
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: minScrollExtent,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      msg,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: DopamineTheme.accentRed,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton(
                                      onPressed: _scheduleFetch,
                                      child: Text(l10n.retry),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    final items = _posts;
                    if (items.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: minScrollExtent,
                            child: Center(
                              child: Text(
                                l10n.emptyState,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: DopamineTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        24 + homeShellBottomInset(context),
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final p = items[i];
                        return CommunityPostCard(
                          post: p,
                          locale: locale,
                          myUid: myUid,
                          onOpenAuthorProfile: _openAuthorProfile,
                          onToggleLike: (post) => _toggleLike(i, post),
                          onOpenPostDetail: _openPostDetail,
                          onEditOwnPost: _openEditCompose,
                          onDeleteOwnPost: _deleteCommunityPost,
                          onReportPost: _reportCommunityPost,
                          onBlockAuthor: _blockAuthorFromPost,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
