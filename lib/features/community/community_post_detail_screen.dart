import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import '../../auth/dopamine_user.dart';
import '../../auth/present_dopamine_auth_screen.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/models/asset_comment.dart';
import '../../data/models/community_post.dart';
import '../../data/models/ranked_asset.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/dopamine_theme.dart';
import '../asset/asset_detail_screen.dart';
import 'community_compose_screen.dart';
import 'community_report_sheet.dart';
import '../profile/public_profile_screen.dart';

/// 커뮤니티 루트 글 + 스레드 댓글·답글
class CommunityPostDetailScreen extends StatefulWidget {
  const CommunityPostDetailScreen({
    super.key,
    required this.post,
    required this.locale,
    this.myUid,
    this.followingByUid,
    this.onToggleFollow,
    this.onPostUpdated,
  });

  final CommunityPost post;
  final String locale;
  final String? myUid;
  final Map<String, bool>? followingByUid;
  final Future<void> Function(CommunityPost p)? onToggleFollow;
  final void Function(CommunityPost updated)? onPostUpdated;

  static Future<bool> open(
    BuildContext context, {
    required CommunityPost post,
    required String locale,
    String? myUid,
    Map<String, bool>? followingByUid,
    Future<void> Function(CommunityPost p)? onToggleFollow,
    void Function(CommunityPost updated)? onPostUpdated,
  }) async {
    final r = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (ctx) => CommunityPostDetailScreen(
          post: post,
          locale: locale,
          myUid: myUid,
          followingByUid: followingByUid,
          onToggleFollow: onToggleFollow,
          onPostUpdated: onPostUpdated,
        ),
      ),
    );
    return r ?? false;
  }

  @override
  State<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  late CommunityPost _post = widget.post;
  List<AssetComment>? _thread;
  Object? _loadError;
  bool _loading = true;
  bool _threadDirty = false;

  final _composer = TextEditingController();
  bool _sending = false;

  String? _replyParentId;
  String? _replyParentName;

  late bool _following;

  /// 부모가 `myUid`를 안 넘겨도 로그인 상태면 메뉴(수정·삭제·신고·차단)가 보이도록 함
  String? get _effectiveMyUid =>
      widget.myUid ?? FirebaseAuth.instance.currentUser?.uid;

  bool get _showOwnPostMenu =>
      _effectiveMyUid != null && _effectiveMyUid == _post.authorUid;

  bool get _showOtherPostMenu =>
      _effectiveMyUid != null && _effectiveMyUid != _post.authorUid;

  @override
  void initState() {
    super.initState();
    _following = widget.followingByUid?[_post.authorUid] ?? false;
    _loadThread();
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _loadThread() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final fb = FirebaseAuth.instance.currentUser;
    final token = await fb?.getIdToken();
    try {
      final list = await DopamineApi.fetchAssetCommentThread(
        rootCommentId: _post.id,
        idToken: token,
      );
      if (!mounted) return;
      AssetComment? rootRow;
      for (final c in list) {
        if (c.id == _post.id) {
          rootRow = c;
          break;
        }
      }
      setState(() {
        _thread = list;
        _loading = false;
        if (rootRow != null) {
          _post = CommunityPost(
            id: _post.id,
            body: rootRow.body,
            title: rootRow.title,
            imageUrls: rootRow.imageUrls,
            authorUid: _post.authorUid,
            authorDisplayName: _post.authorDisplayName,
            authorPhotoUrl: _post.authorPhotoUrl,
            createdAt: _post.createdAt,
            assetSymbol: _post.assetSymbol,
            assetClass: _post.assetClass,
            assetDisplayName:
                rootRow.assetDisplayName ?? _post.assetDisplayName,
            replyCount: _totalReplyCount(list),
            likeCount: rootRow.likeCount,
            likedByMe: rootRow.likedByMe,
            moderationHiddenFromPublic: rootRow.moderationHiddenFromPublic,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  Map<String?, List<AssetComment>> _groupByParent(List<AssetComment> items) {
    final m = <String?, List<AssetComment>>{};
    for (final c in items) {
      m.putIfAbsent(c.parentId, () => []).add(c);
    }
    for (final list in m.values) {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return m;
  }

  int _totalReplyCount(List<AssetComment> items) {
    return items.where((c) => c.id != _post.id).length;
  }

  Future<void> _toggleRootLike() async {
    final l10n = AppLocalizations.of(context)!;
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityLikeLogin)),
      );
      await presentDopamineAuthScreen(context);
      return;
    }
    final token = await fb.getIdToken();
    if (token == null || !mounted) return;
    try {
      final r = await DopamineApi.toggleCommentLike(
        idToken: token,
        commentId: _post.id,
      );
      if (!mounted) return;
      setState(() {
        _post = _post.copyWith(likeCount: r.likeCount, likedByMe: r.liked);
      });
      widget.onPostUpdated?.call(_post);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorLoadFailed)),
      );
    }
  }

  Future<void> _toggleCommentLike(AssetComment c) async {
    final l10n = AppLocalizations.of(context)!;
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityLikeLogin)),
      );
      await presentDopamineAuthScreen(context);
      return;
    }
    final token = await fb.getIdToken();
    if (token == null || !mounted) return;
    try {
      final r = await DopamineApi.toggleCommentLike(
        idToken: token,
        commentId: c.id,
      );
      if (!mounted || _thread == null) return;
      setState(() {
        _thread = _thread!
            .map(
              (x) => x.id == c.id
                  ? x.copyWith(likeCount: r.likeCount, likedByMe: r.liked)
                  : x,
            )
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorLoadFailed)),
      );
    }
  }

  Future<void> _openEditFromDetail() async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) {
      await presentDopamineAuthScreen(context);
      return;
    }
    if (!mounted) return;
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CommunityComposeScreen(editPrefill: _post),
      ),
    );
    if (done == true && mounted) {
      _threadDirty = true;
      await _loadThread();
      widget.onPostUpdated?.call(_post);
    }
  }

  Future<void> _deleteOwnPostFromDetail() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
      ),
    );
    if (ok != true || !mounted) return;
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    final token = await fb.getIdToken();
    if (token == null) return;
    try {
      await DopamineApi.deleteAssetComment(id: _post.id, idToken: token);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException
          ? e.message
          : AppLocalizations.of(context)!.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _reportPostFromDetail() async {
    final l10n = AppLocalizations.of(context)!;
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) {
      await presentDopamineAuthScreen(context);
      return;
    }
    final reasonText = await showCommunityReportSheet(context);
    if (reasonText == null || !mounted) return;
    final token = await fb.getIdToken();
    if (token == null) return;
    try {
      await DopamineApi.reportAssetComment(
        commentId: _post.id,
        idToken: token,
        reason: reasonText,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityReportSubmitted)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _blockAuthorFromDetail() async {
    final l10n = AppLocalizations.of(context)!;
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) {
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
            Text(l10n.communityBlockAuthorMessage(_post.authorDisplayName)),
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
    final token = await fb.getIdToken();
    if (token == null) return;
    try {
      await DopamineApi.blockUser(
        idToken: token,
        targetUid: _post.authorUid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityUserBlocked)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _sendComment() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _composer.text.trim();
    if (text.isEmpty || text.length > 2000) return;
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) {
      await presentDopamineAuthScreen(context);
      return;
    }
    final token = await fb.getIdToken();
    if (token == null || !mounted) return;
    setState(() => _sending = true);
    try {
      final parentId = _replyParentId ?? _post.id;
      await DopamineApi.postAssetComment(
        symbol: _post.assetSymbol,
        assetClass: _post.assetClass,
        body: text,
        parentId: parentId,
        assetDisplayName: _post.assetDisplayName,
        idToken: token,
      );
      if (!mounted) return;
      _composer.clear();
      setState(() {
        _replyParentId = null;
        _replyParentName = null;
        _threadDirty = true;
      });
      await _loadThread();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.assetPostsSendError)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _onFollowPressed() async {
    if (widget.onToggleFollow == null) return;
    final auth = context.read<AuthProvider<DopamineUser>>();
    if (!auth.isLoggedIn()) {
      await presentDopamineAuthScreen(context);
      return;
    }
    try {
      await widget.onToggleFollow!(_post);
      if (mounted) setState(() => _following = !_following);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadFailed)),
        );
      }
    }
  }

  void _openAuthorProfile() {
    PublicProfileScreen.open(
      context,
      authorUid: _post.authorUid,
      authorName: _post.authorDisplayName,
      authorPhotoUrl: _post.authorPhotoUrl,
    );
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

  Widget _commentNode(
    AssetComment c,
    int depth,
    Map<String?, List<AssetComment>> byParent,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final timeStr = DateFormat.yMMMd(widget.locale)
        .add_jm()
        .format(c.createdAt.toLocal());
    final children = byParent[c.id] ?? const <AssetComment>[];

    return Padding(
      padding: EdgeInsets.only(left: depth * 12.0, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.white.withValues(alpha: depth > 0 ? 0.14 : 0),
                  width: 2,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.authorDisplayName,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              timeStr,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: DopamineTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => setState(() {
                                _replyParentId = c.id;
                                _replyParentName = c.authorDisplayName;
                              }),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: DopamineTheme.neonGreen,
                              ),
                              child: Text(l10n.assetPostsReply),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggleCommentLike(c),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            c.likedByMe
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: c.likedByMe
                                ? DopamineTheme.accentRed
                                : DopamineTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${c.likeCount}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: DopamineTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...children.map(
            (ch) => _commentNode(ch, depth + 1, byParent, l10n, theme),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final timeStr = DateFormat.yMMMd(widget.locale)
        .add_jm()
        .format(_post.createdAt.toLocal());
    final assetName = _post.assetDisplayName?.trim();
    final showFollow = widget.onToggleFollow != null &&
        widget.myUid != null &&
        _post.authorUid != widget.myUid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(_threadDirty),
        ),
        title: Text(l10n.communityPostDetailTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading && _thread == null
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DopamineTheme.neonGreen,
                    ),
                  )
                : _loadError != null && _thread == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _loadError is ApiException
                                    ? (_loadError as ApiException).message
                                    : l10n.errorLoadFailed,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _loadThread,
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        children: [
                          _buildPostHeader(
                            theme,
                            l10n,
                            assetName,
                            timeStr,
                            showFollow,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.communityCommentsTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: DopamineTheme.neonGreen,
                            ),
                          ),
                          if (_thread != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.communityCommentCount(
                                _totalReplyCount(_thread!),
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: DopamineTheme.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (_thread != null)
                            Builder(
                              builder: (context) {
                                final byParent = _groupByParent(_thread!);
                                final direct =
                                    byParent[_post.id] ?? const <AssetComment>[];
                                if (direct.isEmpty) {
                                  return Text(
                                    l10n.emptyState,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: DopamineTheme.textSecondary,
                                    ),
                                  );
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    for (final c in direct)
                                      _commentNode(
                                        c,
                                        0,
                                        byParent,
                                        l10n,
                                        theme,
                                      ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
          ),
          Material(
            elevation: 8,
            color: theme.scaffoldBackgroundColor,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_replyParentName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${l10n.assetPostsReplying} · $_replyParentName',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: DopamineTheme.neonGreen,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() {
                                _replyParentId = null;
                                _replyParentName = null;
                              }),
                              child: Text(l10n.assetPostsCancelReply),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _composer,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: l10n.assetPostsPlaceholder,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _sending ? null : _sendComment,
                          style: FilledButton.styleFrom(
                            backgroundColor: DopamineTheme.neonGreen,
                            foregroundColor: const Color(0xFF0A0A0A),
                          ),
                          child: _sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF0A0A0A),
                                  ),
                                )
                              : Text(l10n.assetPostsPublish),
                        ),
                      ],
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

  Widget _buildPostHeader(
    ThemeData theme,
    AppLocalizations l10n,
    String? assetName,
    String timeStr,
    bool showFollow,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_post.moderationHiddenFromPublic &&
            _effectiveMyUid != null &&
            _effectiveMyUid == _post.authorUid) ...[
          _ModerationHiddenNotice(l10n: l10n),
          const SizedBox(height: 10),
        ],
        if (assetName != null && assetName.isNotEmpty)
          Text(
            assetName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DopamineTheme.neonGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DopamineTheme.neonGreen.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                _post.assetSymbol,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: DopamineTheme.neonGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _classBadge(_post.assetClass, l10n),
              style: theme.textTheme.labelSmall?.copyWith(
                color: DopamineTheme.textSecondary,
              ),
            ),
            const Spacer(),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l10n.communityOpenAssetDetail,
              icon: Icon(
                Icons.info_outline_rounded,
                color: DopamineTheme.neonGreen.withValues(alpha: 0.95),
              ),
              onPressed: () {
                AssetDetailScreen.open(
                  context,
                  RankedAsset.communityShell(
                    symbol: _post.assetSymbol,
                    assetClass: _post.assetClass,
                    displayName: (assetName != null && assetName.isNotEmpty)
                        ? assetName
                        : null,
                  ),
                );
              },
            ),
            if (_showOwnPostMenu || _showOtherPostMenu)
              PopupMenuButton<String>(
                tooltip: l10n.communityMoreMenu,
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: DopamineTheme.textSecondary.withValues(alpha: 0.95),
                  size: 26,
                ),
                onSelected: (v) async {
                  if (v == 'edit') {
                    await _openEditFromDetail();
                  } else if (v == 'delete') {
                    await _deleteOwnPostFromDetail();
                  } else if (v == 'report') {
                    await _reportPostFromDetail();
                  } else if (v == 'block') {
                    await _blockAuthorFromDetail();
                  }
                },
                itemBuilder: (ctx) {
                  if (_showOwnPostMenu) {
                    return [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.profileActivityEditPost),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          l10n.profileActivityDeletePost,
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                      ),
                    ];
                  }
                  return [
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 20,
                            color: DopamineTheme.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(l10n.communityReportPostShort),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 20,
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.communityBlockAuthorShort,
                            style: TextStyle(
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
          ],
        ),
        if (_post.title != null && _post.title!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            _post.title!.trim(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (_post.imageUrls.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _post.imageUrls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _post.imageUrls[i],
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 88,
                      height: 88,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          _post.body,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: _openAuthorProfile,
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    _DetailAvatar(
                      url: _post.authorPhotoUrl,
                      name: _post.authorDisplayName,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _post.authorDisplayName,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (showFollow)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  tooltip: _following
                                      ? l10n.communityUnfollow
                                      : l10n.communityFollow,
                                  onPressed: _onFollowPressed,
                                  icon: Icon(
                                    _following
                                        ? Icons.how_to_reg_rounded
                                        : Icons.person_add_alt_1_rounded,
                                    size: 20,
                                    color: _following
                                        ? DopamineTheme.textSecondary
                                        : DopamineTheme.neonGreen,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            timeStr,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: DopamineTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleRootLike,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _post.likedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 22,
                    color: _post.likedByMe
                        ? DopamineTheme.accentRed
                        : DopamineTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.communityLikeCount(_post.likeCount),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: DopamineTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModerationHiddenNotice extends StatelessWidget {
  const _ModerationHiddenNotice({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.amber.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.visibility_off_outlined,
              size: 20,
              color: Colors.amber.shade700,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.communityPostHiddenByReportNotice,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.35,
                  color: DopamineTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailAvatar extends StatelessWidget {
  const _DetailAvatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final u = url?.trim();
    if (u != null && u.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          u,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(context),
        ),
      );
    }
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    final t = name.trim();
    final letter =
        t.isEmpty ? '?' : String.fromCharCode(t.runes.first).toUpperCase();
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      child: Text(
        letter,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: DopamineTheme.textSecondary,
        ),
      ),
    );
  }
}
