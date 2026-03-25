import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import '../../auth/dopamine_user.dart';
import '../../auth/present_dopamine_auth_screen.dart';
import '../../core/feed/home_asset_suggestions.dart';
import '../../core/navigation/home_shell_navigation.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/models/community_post.dart';
import '../../data/models/ranked_asset.dart';
import '../../theme/dopamine_theme.dart';
import '../asset/asset_detail_screen.dart';
import 'community_compose_screen.dart';

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
  Map<String, bool> _followingByUid = const {};

  HomeShellNavigation? _nav;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  bool _symbolFilterActive = false;
  String? _symbolFilterSymbol;
  String? _symbolFilterClass;

  final List<String> _bodySearchTerms = [];

  @override
  void initState() {
    super.initState();
    _scheduleFetch();
  }

  Future<void> _scheduleFetch() async {
    final gen = ++_fetchGen;
    setState(() {
      _loading = true;
      _fetchError = null;
    });
    String? idToken;
    final fb = FirebaseAuth.instance.currentUser;
    if (fb != null) {
      idToken = await fb.getIdToken();
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
      await _loadFollowStatus(items, gen);
    } catch (e) {
      if (!mounted || gen != _fetchGen) return;
      setState(() {
        _fetchError = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadFollowStatus(List<CommunityPost> posts, int gen) async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null || !mounted || gen != _fetchGen) {
      if (mounted && gen == _fetchGen) {
        setState(() => _followingByUid = {});
      }
      return;
    }
    final uids = posts
        .map((p) => p.authorUid)
        .toSet()
        .where((u) => u != fb.uid)
        .toList();
    if (uids.isEmpty) {
      if (mounted && gen == _fetchGen) {
        setState(() => _followingByUid = {});
      }
      return;
    }
    final token = await fb.getIdToken();
    if (token == null || !mounted || gen != _fetchGen) return;
    try {
      final map = await DopamineApi.fetchFollowStatus(
        idToken: token,
        targetUids: uids,
      );
      if (!mounted || gen != _fetchGen) return;
      setState(() => _followingByUid = map);
    } catch (_) {
      if (mounted && gen == _fetchGen) {
        setState(() => _followingByUid = {});
      }
    }
  }

  Future<void> _toggleFollow(CommunityPost p) async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) {
      await presentDopamineAuthScreen(context);
      return;
    }
    if (p.authorUid == fb.uid) return;
    final token = await fb.getIdToken();
    if (token == null || !mounted) return;
    final now = _followingByUid[p.authorUid] ?? false;
    try {
      if (now) {
        await DopamineApi.unfollowUser(idToken: token, targetUid: p.authorUid);
      } else {
        await DopamineApi.followUser(idToken: token, targetUid: p.authorUid);
      }
      if (!mounted) return;
      setState(() {
        _followingByUid = Map<String, bool>.from(_followingByUid)
          ..[p.authorUid] = !now;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadFailed)),
      );
    }
  }

  Future<void> _toggleLike(int index, CommunityPost p) async {
    final l10n = AppLocalizations.of(context)!;
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.communityLikeLogin)));
      await presentDopamineAuthScreen(context);
      return;
    }
    final token = await fb.getIdToken();
    if (token == null || !mounted) return;
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

  void _onSort(String next) {
    if (next == _sort) return;
    setState(() {
      _sort = next;
    });
    _scheduleFetch();
  }

  void _handleNav() {
    final nav = _nav;
    if (nav == null) return;
    final f = nav.takePendingFilter();
    if (f == null) return;
    if (!mounted) return;
    setState(() {
      _symbolFilterActive = true;
      _symbolFilterSymbol = f.symbol;
      _symbolFilterClass = f.assetClass;
      _bodySearchTerms.clear();
      _searchController.clear();
    });
    _scheduleFetch();
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
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) {
      await presentDopamineAuthScreen(context);
      return;
    }
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (ctx) => CommunityComposeScreen(
          initialSymbol: _symbolFilterActive ? _symbolFilterSymbol : null,
          initialAssetClass: _symbolFilterActive ? _symbolFilterClass : null,
        ),
      ),
    );
    if (done == true && mounted) {
      _scheduleFetch();
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
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    context.watch<HomeAssetSuggestions>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navCommunity),
        actions: [
          if (!auth.isLoggedIn())
            TextButton(
              onPressed: () => presentDopamineAuthScreen(context),
              child: Text(
                l10n.actionLogin,
                style: const TextStyle(
                  color: DopamineTheme.neonGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                          deleteIcon: const Icon(Icons.close_rounded, size: 18),
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
                          deleteIcon: const Icon(Icons.close_rounded, size: 18),
                          onDeleted: () => _removeBodyTerm(term),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
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
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                    child: RawAutocomplete<String>(
                      textEditingController: _searchController,
                      focusNode: _searchFocusNode,
                      displayStringForOption: (s) => s,
                      optionsBuilder: (TextEditingValue value) {
                        final q = value.text;
                        if (q.trim().isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return context.read<HomeAssetSuggestions>().matching(q);
                      },
                      onSelected: (String selection) {
                        setState(() {
                          _searchController.text = selection;
                        });
                        _submitSearch(selection);
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
                            void Function(String) onSelected,
                            Iterable<String> options,
                          ) {
                            final list = options.toList();
                            if (list.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFF1A1525),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 220,
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
                                      final opt = list[i];
                                      return ListTile(
                                        dense: true,
                                        title: Text(
                                          opt,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    DopamineTheme.textPrimary,
                                              ),
                                        ),
                                        onTap: () => onSelected(opt),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
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
            child: Builder(
              builder: (context) {
                if (_loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DopamineTheme.neonGreen,
                    ),
                  );
                }
                if (_fetchError != null) {
                  final err = _fetchError!;
                  final msg = err is ApiException
                      ? err.message
                      : err.toString();
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
                            onPressed: _scheduleFetch,
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final items = _posts;
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.emptyState,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DopamineTheme.textSecondary,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final p = items[i];
                    final assetName = p.assetDisplayName?.trim();
                    final timeStr = DateFormat.yMMMd(
                      locale,
                    ).add_jm().format(p.createdAt.toLocal());
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (assetName != null &&
                                          assetName.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          child: Text(
                                            assetName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  DopamineTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: DopamineTheme.neonGreen
                                                  .withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: DopamineTheme.neonGreen
                                                    .withValues(
                                                  alpha: 0.35,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              p.assetSymbol,
                                              style: theme
                                                  .textTheme.labelMedium
                                                  ?.copyWith(
                                                color: DopamineTheme.neonGreen,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _classBadge(
                                                p.assetClass,
                                                l10n,
                                              ),
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color: DopamineTheme
                                                    .textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                  tooltip: l10n.communityOpenAssetDetail,
                                  icon: Icon(
                                    Icons.info_outline_rounded,
                                    color: DopamineTheme.neonGreen.withValues(
                                      alpha: 0.95,
                                    ),
                                    size: 30,
                                  ),
                                  onPressed: () {
                                    AssetDetailScreen.open(
                                      context,
                                      RankedAsset.communityShell(
                                        symbol: p.assetSymbol,
                                        assetClass: p.assetClass,
                                        displayName: (assetName != null &&
                                                assetName.isNotEmpty)
                                            ? assetName
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            if (p.title != null &&
                                p.title!.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                p.title!.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: DopamineTheme.textPrimary,
                                ),
                              ),
                            ],
                            if (p.imageUrls.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 72,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: p.imageUrls.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (ctx, imgIdx) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        p.imageUrls[imgIdx],
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 72,
                                                  height: 72,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.06),
                                                ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              p.body,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: DopamineTheme.textPrimary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.authorDisplayName,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: DopamineTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  timeStr,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: DopamineTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (auth.isLoggedIn() &&
                                    myUid != null &&
                                    p.authorUid != myUid) ...[
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor:
                                          (_followingByUid[p.authorUid] ??
                                              false)
                                          ? DopamineTheme.textSecondary
                                          : DopamineTheme.neonGreen,
                                    ),
                                    onPressed: () => _toggleFollow(p),
                                    child: Text(
                                      (_followingByUid[p.authorUid] ?? false)
                                          ? l10n.communityUnfollow
                                          : l10n.communityFollow,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                const Spacer(),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _toggleLike(i, p),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        p.likedByMe
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        size: 20,
                                        color: p.likedByMe
                                            ? DopamineTheme.accentRed
                                            : DopamineTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.communityLikeCount(p.likeCount),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color:
                                                  DopamineTheme.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (p.replyCount > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                l10n.communityReplyCount(p.replyCount),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: DopamineTheme.neonGreen.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
