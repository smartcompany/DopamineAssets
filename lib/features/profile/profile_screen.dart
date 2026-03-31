import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import '../../auth/dopamine_user.dart';
import '../../auth/present_dopamine_auth_screen.dart';
import '../../core/navigation/home_shell_bottom_inset.dart';
import '../../core/navigation/home_shell_navigation.dart';
import '../../core/profile/profile_stats_store.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../core/text/ugc_banned_words.dart';
import '../../core/storage/community_post_image_upload.dart';
import '../../data/models/community_post.dart';
import '../../data/models/profile_activity_item.dart';
import '../../data/models/ranked_asset.dart';
import '../../theme/dopamine_theme.dart';
import '../asset/asset_detail_screen.dart';
import '../community/community_compose_screen.dart';
import '../community/community_post_card.dart';
import '../community/community_post_detail_screen.dart';
import 'blocked_users_screen.dart';
import 'follow_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  StreamSubscription<User?>? _authSub;
  HomeShellNavigation? _shellNav;
  AuthProvider<DopamineUser>? _authProvider;

  /// 홈(0) · 커뮤니티(1) · 프로필(2) — 프로필 탭으로 **들어올 때만** 갱신
  int _prevShellTabIndex = -1;

  bool _loading = false;
  Object? _loadError;
  List<ProfileActivityItem> _activity = const [];

  bool _savingName = false;
  bool _uploadingPhoto = false;
  bool _hydratingProfile = false;

  bool _isAppSignedIn(AuthProvider<DopamineUser> auth) {
    return auth.isLoggedIn();
  }

  Future<void> _hydrateProfileIfMissing({
    required AuthProvider<DopamineUser> auth,
    required User firebaseUser,
  }) async {
    if (_hydratingProfile) return;
    if (auth.userProfile != null) return;
    final firebaseName = firebaseUser.displayName?.trim();
    if (firebaseName == null || firebaseName.isEmpty) return;

    _hydratingProfile = true;
    try {
      final token = await firebaseUser.getIdToken();
      if (token == null || token.isEmpty) return;
      await DopamineApi.patchProfileDisplayName(
        idToken: token,
        displayName: firebaseName,
      );
      if (!mounted) return;
      auth.setUserProfile(
        DopamineUser(
          uid: firebaseUser.uid,
          displayName: firebaseName,
          photoUrl: null,
        ),
      );
      _syncNameField(firebaseName);
    } catch (e) {
      debugPrint(
        '[Profile] hydrate profile from firebase displayName failed: $e',
      );
    } finally {
      _hydratingProfile = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider<DopamineUser>>();
    _authProvider!.addListener(_handleAuthProviderUpdate);
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) async {
      if (!mounted) return;
      final auth = context.read<AuthProvider<DopamineUser>>();
      if (_isAppSignedIn(auth) && u != null) {
        await _hydrateProfileIfMissing(auth: auth, firebaseUser: u);
        _syncNameField(auth.userProfile?.displayName ?? u.displayName);
        await _loadData();
      } else {
        ProfileStatsStore.instance.clear();
        setState(() {
          _activity = const [];
          _loadError = null;
          _loading = false;
          _nameController.clear();
        });
      }
    });
  }

  void _handleShellNav() {
    final nav = _shellNav;
    if (nav == null || !mounted) return;
    final t = nav.tabIndex;
    if (t == 2 && _prevShellTabIndex != 2) {
      final auth = context.read<AuthProvider<DopamineUser>>();
      if (_isAppSignedIn(auth) && FirebaseAuth.instance.currentUser != null) {
        // 프로필 탭 진입 시에는 활동 내역만 조용히 갱신합니다.
        _reloadActivityOnly();
      }
    }
    _prevShellTabIndex = t;
  }

  Future<void> _reloadActivityOnly() async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    final token = await fb.getIdToken();
    if (token == null || token.isEmpty) return;
    try {
      final act = await DopamineApi.fetchProfileActivity(idToken: token);
      if (!mounted) return;
      setState(() {
        _activity = act;
      });
    } catch (_) {
      // 탭 진입 동기화는 조용히 처리합니다.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<HomeShellNavigation>();
    if (!identical(_shellNav, nav)) {
      _shellNav?.removeListener(_handleShellNav);
      _shellNav = nav;
      _prevShellTabIndex = nav.tabIndex;
      _shellNav!.addListener(_handleShellNav);
    }
  }

  @override
  void dispose() {
    _shellNav?.removeListener(_handleShellNav);
    _authSub?.cancel();
    _authProvider?.removeListener(_handleAuthProviderUpdate);
    _nameController.dispose();
    super.dispose();
  }

  void _handleAuthProviderUpdate() {
    if (!mounted) return;
    if (_savingName) return; // 사용자가 입력 중일 때는 덮어쓰지 않습니다.

    final dn = _authProvider?.userProfile?.displayName;
    if (dn == null) return;

    final normalized = dn.trim();
    if (normalized.isEmpty) return;

    // 재로그인 시점에 auth.userProfile이 늦게 들어오면,
    // 기존 authStateChanges 콜백에서 동기화가 먼저 끝나서 이름이 안 보일 수 있습니다.
    // provider 업데이트를 감지해서 컨트롤러를 다시 채웁니다.
    if (_nameController.text.trim() != normalized) {
      _syncNameField(dn);
    }
  }

  void _syncNameField(String? displayName) {
    final n = displayName?.trim();
    if (n != null && n.isNotEmpty) {
      _nameController.text = n;
    }
  }

  String _extFromPath(String path) {
    final i = path.lastIndexOf('.');
    if (i < 0 || i >= path.length - 1) return 'jpg';
    return path.substring(i + 1).toLowerCase();
  }

  String _mimeForExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _pickProfilePhoto(AppLocalizations l10n) async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (x == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await x.readAsBytes();
      final token = await fb.getIdToken();
      if (token == null || token.isEmpty) return;
      final ext = _extFromPath(x.path);
      final url = await uploadProfileImage(
        idToken: token,
        bytes: bytes,
        filename: 'avatar.$ext',
        contentType: _mimeForExt(ext),
      );
      await DopamineApi.patchProfilePhotoUrl(idToken: token, photoUrl: url);
      if (!mounted) return;
      final auth = context.read<AuthProvider<DopamineUser>>();
      final current = auth.userProfile;
      if (current != null) {
        auth.setUserProfile(
          DopamineUser(
            uid: current.uid,
            displayName: current.displayName,
            photoUrl: url,
          ),
        );
      }
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profilePhotoSaved)));
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _removeProfilePhoto(AppLocalizations l10n) async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final token = await fb.getIdToken();
      if (token == null || token.isEmpty) return;
      await DopamineApi.patchProfilePhotoUrl(idToken: token, photoUrl: null);
      if (!mounted) return;
      final auth = context.read<AuthProvider<DopamineUser>>();
      final current = auth.userProfile;
      if (current != null) {
        auth.setUserProfile(
          DopamineUser(
            uid: current.uid,
            displayName: current.displayName,
            photoUrl: null,
          ),
        );
      }
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profilePhotoRemoved)));
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _loadData({bool showLoading = true}) async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;

    _syncNameField(
      context.read<AuthProvider<DopamineUser>>().userProfile?.displayName,
    );

    final token = await fb.getIdToken();
    if (token == null || token.isEmpty) return;

    if (showLoading) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final stats = await DopamineApi.fetchProfileStats(idToken: token);
      final act = await DopamineApi.fetchProfileActivity(idToken: token);
      if (!mounted) return;
      ProfileStatsStore.instance.apply(stats);
      setState(() {
        _activity = act;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  Future<void> _saveDisplayName(AppLocalizations l10n) async {
    final text = _nameController.text.trim();
    if (text.isEmpty || text.length > 80) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorLoadFailed)));
      return;
    }

    final bad = UgcBannedWords.firstMatch(text);
    if (bad != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.ugcBannedWordsMessage(bad))));
      return;
    }

    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;

    setState(() => _savingName = true);
    try {
      final token = await fb.getIdToken();
      if (token != null && token.isNotEmpty) {
        await DopamineApi.patchProfileDisplayName(
          idToken: token,
          displayName: text,
        );
      }
      if (!mounted) return;
      final auth = context.read<AuthProvider<DopamineUser>>();
      final current = auth.userProfile;
      auth.setUserProfile(
        DopamineUser(
          uid: fb.uid,
          displayName: text,
          photoUrl: current?.photoUrl,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileDisplayNameSaved)));
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileDeleteTitle),
        content: Text(l10n.profileDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.profileDeleteCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DopamineTheme.accentRed,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.profileDeleteConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider<DopamineUser>>();
    final uid = auth.currentUid();
    if (uid == null || uid.isEmpty) return;

    try {
      final token = await auth.getIdToken();
      if (token == null || token.isEmpty) {
        throw StateError('invalid-id-token');
      }
      debugPrint(
        '[Dopamine][delete-account] request /api/profile/me uid=$uid tokenLen=${token.length}',
      );

      try {
        await DopamineApi.deleteProfileData(idToken: token);
      } on ApiException catch (e) {
        debugPrint(
          '[Dopamine][delete-account] deleteProfileData failed: ${e.message}',
        );
        if (!context.mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
        return;
      } catch (e) {
        debugPrint('[Dopamine][delete-account] deleteProfileData failed: $e');
        if (!context.mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorLoadFailed)));
        return;
      }

      try {
        await auth.deleteAccount();
      } on FirebaseAuthException catch (e) {
        debugPrint(
          '[Dopamine][delete-account] auth.deleteAccount failed: code=${e.code} message=${e.message}',
        );
        if (!context.mounted) return;
        if (e.code == 'requires-recent-login') {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.profileRequiresRecentLogin)),
          );
        } else {
          messenger.showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
        }
        return;
      } catch (e) {
        debugPrint('[Dopamine][delete-account] auth.deleteAccount failed: $e');
        if (!context.mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorLoadFailed)));
        return;
      }
    } on StateError {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorLoadFailed)));
    } catch (e) {
      debugPrint('[Dopamine][delete-account] unexpected failed: $e');
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorLoadFailed)));
    }
  }

  Future<void> _logout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await context.read<AuthProvider<DopamineUser>>().logout();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileLogoutDone)));
    }
  }

  String _activityKindLabel(AppLocalizations l10n, String kind) {
    switch (kind) {
      case 'my_post':
        return l10n.profileActivityMyPost;
      case 'my_reply':
        return l10n.profileActivityMyReply;
      case 'reply_on_my_post':
        return l10n.profileActivityReplyOnPost;
      case 'like_received':
        return l10n.profileActivityLikeReceived;
      default:
        return kind;
    }
  }

  Future<void> _openActivityItem(
    BuildContext context,
    ProfileActivityItem item,
  ) async {
    AssetDetailScreen.open(
      context,
      RankedAsset.communityShell(
        symbol: item.assetSymbol,
        assetClass: item.assetClass,
      ),
    );
  }

  /// like_received / reply_on_my_post → 커뮤니티 게시글 본문(스레드 루트)
  Future<void> _openActivityThreadPost(
    BuildContext context,
    ProfileActivityItem item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) {
      await presentDopamineAuthScreen(context);
      return;
    }
    final token = await fb.getIdToken();
    if (token == null || token.isEmpty || !mounted) return;

    var rootId = item.threadRootCommentId?.trim();
    if (rootId == null || rootId.isEmpty) {
      rootId = await _resolveThreadRootCommentIdViaApi(
        commentId: item.commentId,
        idToken: token,
      );
    }
    if (rootId == null || rootId.isEmpty || !context.mounted) return;

    try {
      final root = await DopamineApi.fetchAssetCommentById(
        id: rootId,
        idToken: token,
      );
      if (!context.mounted) return;
      final post = CommunityPost(
        id: root.id,
        body: root.body,
        title: root.title,
        imageUrls: root.imageUrls,
        authorUid: root.authorUid,
        authorDisplayName: root.authorDisplayName,
        authorPhotoUrl: null,
        createdAt: root.createdAt,
        assetSymbol: root.assetSymbol ?? item.assetSymbol,
        assetClass: root.assetClass ?? item.assetClass,
        assetDisplayName: root.assetDisplayName ?? item.assetDisplayName,
        replyCount: 0,
        likeCount: root.likeCount,
        likedByMe: root.likedByMe,
        moderationHiddenFromPublic: root.moderationHiddenFromPublic,
      );
      await _openActivityPostDetail(post);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<String?> _resolveThreadRootCommentIdViaApi({
    required String commentId,
    required String idToken,
  }) async {
    var cur = commentId;
    for (var i = 0; i < 50; i++) {
      final c = await DopamineApi.fetchAssetCommentById(
        id: cur,
        idToken: idToken,
      );
      final p = c.parentId?.trim();
      if (p == null || p.isEmpty) return c.id;
      cur = p;
    }
    return cur;
  }

  Future<void> _editOwnActivity(
    BuildContext context,
    ProfileActivityItem item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => CommunityComposeScreen(editCommentId: item.commentId),
      ),
    );
    if ((result == true || result is CommunityPost) && mounted) {
      await _loadData();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileActivityPostUpdated)));
    }
  }

  ProfileActivityItem? _activityItemForCommentId(String commentId) {
    for (final a in _activity) {
      if (a.commentId == commentId) return a;
    }
    return null;
  }

  Future<void> _openActivityPostDetail(CommunityPost p) async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final changed = await CommunityPostDetailScreen.open(
      context,
      post: p,
      locale: locale,
      myUid: fb.uid,
      onPostUpdated: (_) {
        if (mounted) {
        _loadData(showLoading: false);
        }
      },
    );
    if (changed && mounted) {
      await _loadData();
    }
  }

  Future<void> _toggleActivityLike(CommunityPost p) async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await presentDopamineAuthScreen(context);
      return;
    }
    final token = await user.getIdToken();
    if (token == null || !mounted) return;
    try {
      await DopamineApi.toggleCommentLike(idToken: token, commentId: p.id);
      if (!mounted) return;
      await _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorLoadFailed)));
    }
  }

  Future<void> _deleteOwnActivity(
    BuildContext context,
    ProfileActivityItem item,
  ) async {
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
    if (ok != true || !context.mounted) return;
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    final token = await fb.getIdToken();
    if (token == null || token.isEmpty) return;
    try {
      await DopamineApi.deleteAssetComment(id: item.commentId, idToken: token);
      if (!context.mounted) return;
      await _loadData();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileActivityPostDeleted)));
    } catch (e) {
      if (!context.mounted) return;
      // 이미 다른 화면에서 지워진 항목이면 로컬 목록만 정리하고 성공으로 간주합니다.
      if (e is ApiException && e.message.toLowerCase().contains('not found')) {
        setState(() {
          _activity = _activity.where((a) => a.commentId != item.commentId).toList();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileActivityPostDeleted)));
        unawaited(_loadData());
        return;
      }
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Widget _activityActionButtons(
    BuildContext context,
    ProfileActivityItem item,
    AppLocalizations l10n,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 22),
          color: DopamineTheme.textSecondary,
          tooltip: l10n.profileActivityEditPost,
          onPressed: () => _editOwnActivity(context, item),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 22),
          color: DopamineTheme.textSecondary,
          tooltip: l10n.profileActivityDeletePost,
          onPressed: () => _deleteOwnActivity(context, item),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    String locale,
    ProfileActivityItem item,
  ) {
    final timeStr = DateFormat.yMMMd(locale).add_jm().format(item.at.toLocal());

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
    );

    if ((item.kind == 'my_post' || item.kind == 'my_reply') &&
        !item.hasCommunityCardPayload) {
      return Card(
        clipBehavior: Clip.antiAlias,
        color: Colors.black.withValues(alpha: 0.38),
        elevation: 0,
        shape: cardShape,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _openActivityItem(context, item),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.kind == 'my_post'
                              ? l10n.profileActivityPostOnAsset(
                                  (item.assetDisplayName?.trim().isNotEmpty ==
                                          true)
                                      ? item.assetDisplayName!.trim()
                                      : item.assetSymbol,
                                )
                              : _activityKindLabel(l10n, item.kind),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: DopamineTheme.neonGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.bodyPreview,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: DopamineTheme.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          timeStr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: DopamineTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _activityActionButtons(context, item, l10n),
            ],
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      color: Colors.black.withValues(alpha: 0.38),
      elevation: 0,
      shape: cardShape,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          if (item.kind == 'like_received' || item.kind == 'reply_on_my_post') {
            _openActivityThreadPost(context, item);
          } else {
            _openActivityItem(context, item);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _activityKindLabel(l10n, item.kind),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: DopamineTheme.neonGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.bodyPreview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DopamineTheme.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                timeStr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: DopamineTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignedInBody(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    User fb,
    bool profileSaved,
    String? profilePhotoUrl,
    String locale,
  ) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.profileSignedInSection,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: DopamineTheme.neonGreen,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.profileAccountRefreshTooltip,
                        onPressed: _loading ? null : () => _loadData(),
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: _loading
                              ? DopamineTheme.textSecondary.withValues(
                                  alpha: 0.35,
                                )
                              : DopamineTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _AccountProfilePhotoCard(
                    theme: theme,
                    l10n: l10n,
                    photoUrl: profilePhotoUrl,
                    profileSaved: profileSaved,
                    uploadingPhoto: _uploadingPhoto,
                    onPickPhoto: () => _pickProfilePhoto(l10n),
                    onRemovePhoto: () => _removeProfilePhoto(l10n),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.profileDisplayName,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: DopamineTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          onTapOutside: (_) {
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          maxLength: 80,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: DopamineTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.profileDisplayNameHint,
                            hintStyle: TextStyle(
                              color: DopamineTheme.textSecondary.withValues(
                                alpha: 0.85,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.22),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            counterText: '',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _savingName
                            ? null
                            : () => _saveDisplayName(l10n),
                        style: FilledButton.styleFrom(
                          backgroundColor: DopamineTheme.neonGreen,
                          foregroundColor: const Color(0xFF0A0A0A),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        child: _savingName
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0A0A0A),
                                ),
                              )
                            : Text(l10n.profileSaveDisplayName),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (ProfileStatsStore.instance.stats == null && _loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DopamineTheme.neonGreen,
                          ),
                        ),
                      ),
                    )
                  else if (ProfileStatsStore.instance.stats == null &&
                      _loadError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _loadError is ApiException
                            ? (_loadError as ApiException).message
                            : l10n.errorLoadFailed,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: DopamineTheme.accentRed,
                        ),
                      ),
                    )
                  else if (ProfileStatsStore.instance.stats != null)
                    _StatsRow(
                      stats: ProfileStatsStore.instance.stats!,
                      l10n: l10n,
                    ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _logout(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DopamineTheme.textPrimary,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.profileLogout),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _confirmDelete(context),
                      style: TextButton.styleFrom(
                        foregroundColor: DopamineTheme.accentRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.profileDeleteAccount),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProfileStickyHeaderDelegate(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.profileActivityTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: DopamineTheme.neonGreen,
                  ),
                ),
              ),
            ),
          ),
        ];
      },
      body: _buildActivityList(
        context,
        theme,
        l10n,
        fb,
        profilePhotoUrl,
        locale,
      ),
    );
  }

  Widget _buildActivityList(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    User fb,
    String? profilePhotoUrl,
    String locale,
  ) {
    if (_loading && _activity.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DopamineTheme.neonGreen,
          ),
        ),
      );
    }

    if (_loadError != null && _activity.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _loadError is ApiException
                ? (_loadError as ApiException).message
                : l10n.errorLoadFailed,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DopamineTheme.accentRed,
            ),
          ),
        ),
      );
    }

    if (_activity.isEmpty) {
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
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        28 + homeShellBottomInset(context),
      ),
      itemCount: _activity.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _activity[index];
        return item.hasCommunityCardPayload
            ? CommunityPostCard(
                post: item.toCommunityPost(
                  authorUid: fb.uid,
                  fallbackAuthorDisplayName:
                      _nameController.text.trim().isNotEmpty
                      ? _nameController.text.trim()
                      : 'User',
                  authorPhotoUrl: profilePhotoUrl?.trim().isNotEmpty == true
                      ? profilePhotoUrl!.trim()
                      : null,
                ),
                locale: locale,
                myUid: fb.uid,
                onToggleLike: _toggleActivityLike,
                onOpenPostDetail: _openActivityPostDetail,
                onEditOwnPost: (p) {
                  final i = _activityItemForCommentId(p.id);
                  if (i != null) {
                    _editOwnActivity(context, i);
                  }
                },
                onDeleteOwnPost: (p) {
                  final i = _activityItemForCommentId(p.id);
                  if (i != null) {
                    _deleteOwnActivity(context, i);
                  }
                },
              )
            : _buildActivityCard(context, theme, l10n, locale, item);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider<DopamineUser>>();
    final fb = FirebaseAuth.instance.currentUser;
    final appSignedIn = _isAppSignedIn(auth);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final profileSaved = appSignedIn;
    final profilePhotoUrl = auth.userProfile?.photoUrl;

    return Scaffold(
      body: SafeArea(
        child: appSignedIn
            ? ListenableBuilder(
                listenable: ProfileStatsStore.instance,
                builder: (context, _) {
                  return _buildSignedInBody(
                    context,
                    theme,
                    l10n,
                    fb!,
                    profileSaved,
                    profilePhotoUrl,
                    locale,
                  );
                },
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.profileNotSignedIn,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: DopamineTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => presentDopamineAuthScreen(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: DopamineTheme.neonGreen,
                          foregroundColor: const Color(0xFF0A0A0A),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                        ),
                        child: Text(l10n.actionLogin),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ProfileStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ProfileStickyHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _ProfileStickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

/// 계정 영역 — 프로필 사진 카드 (글래스 톤 + 아이콘 액션)
class _AccountProfilePhotoCard extends StatelessWidget {
  const _AccountProfilePhotoCard({
    required this.theme,
    required this.l10n,
    required this.photoUrl,
    required this.profileSaved,
    required this.uploadingPhoto,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final String? photoUrl;
  final bool profileSaved;
  final bool uploadingPhoto;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final normalizedPhotoUrl = photoUrl?.trim();
    final hasPhoto = profileSaved && normalizedPhotoUrl?.isNotEmpty == true;
    final borderGlow = DopamineTheme.neonGreen.withValues(alpha: 0.35);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.35),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: DopamineTheme.neonGreen.withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: uploadingPhoto ? null : onPickPhoto,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: DopamineTheme.neonGreen.withValues(
                            alpha: 0.12,
                          ),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            borderGlow,
                            DopamineTheme.neonGreen.withValues(alpha: 0.12),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        child: ClipOval(
                          child: _profileAvatarChild(normalizedPhotoUrl),
                        ),
                      ),
                    ),
                  ),
                ),
                if (uploadingPhoto)
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: DopamineTheme.neonGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ProfilePhotoIconAction(
                icon: Icons.add_photo_alternate_rounded,
                tooltip: l10n.profilePhotoTitle,
                foreground: DopamineTheme.neonGreen,
                background: DopamineTheme.neonGreen.withValues(alpha: 0.14),
                borderColor: DopamineTheme.neonGreen.withValues(alpha: 0.35),
                onPressed: uploadingPhoto ? null : onPickPhoto,
              ),
              if (hasPhoto) ...[
                const SizedBox(width: 14),
                _ProfilePhotoIconAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: l10n.profilePhotoRemove,
                  foreground: DopamineTheme.accentRed,
                  background: DopamineTheme.accentRed.withValues(alpha: 0.12),
                  borderColor: DopamineTheme.accentRed.withValues(alpha: 0.35),
                  onPressed: uploadingPhoto ? null : onRemovePhoto,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static Widget _profileAvatarChild(String? normalizedPhotoUrl) {
    if (normalizedPhotoUrl != null && normalizedPhotoUrl.isNotEmpty) {
      return Image.network(
        normalizedPhotoUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.person_rounded,
          size: 52,
          color: DopamineTheme.textSecondary,
        ),
      );
    }
    return Icon(
      Icons.person_rounded,
      size: 52,
      color: DopamineTheme.textSecondary.withValues(alpha: 0.95),
    );
  }
}

class _ProfilePhotoIconAction extends StatelessWidget {
  const _ProfilePhotoIconAction({
    required this.icon,
    required this.tooltip,
    required this.foreground,
    required this.background,
    required this.borderColor,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: background,
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              icon,
              size: 24,
              color: onPressed == null
                  ? foreground.withValues(alpha: 0.35)
                  : foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.l10n});

  final ProfileStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    void refreshCounts() {
      ProfileStatsStore.instance.refreshWithCurrentFirebaseUser();
    }

    return Row(
      children: [
        Expanded(
          child: _StatCell(
            value: stats.postsCount.toString(),
            label: l10n.profileStatPosts,
            onTap: null,
          ),
        ),
        Expanded(
          child: _StatCell(
            value: stats.followingCount.toString(),
            label: l10n.profileStatFollowing,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FollowListScreen(
                    kind: FollowListKind.following,
                    onListChanged: refreshCounts,
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _StatCell(
            value: stats.followersCount.toString(),
            label: l10n.profileStatFollowers,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const FollowListScreen(kind: FollowListKind.followers),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _StatCell(
            value: stats.blockedCount.toString(),
            label: l10n.profileStatBlocked,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      BlockedUsersScreen(onListChanged: refreshCounts),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: DopamineTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: onTap != null
                ? DopamineTheme.neonGreen
                : DopamineTheme.textSecondary,
            fontWeight: FontWeight.w700,
            decoration: onTap != null ? TextDecoration.underline : null,
          ),
        ),
      ],
    );
    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: child,
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: child,
      ),
    );
  }
}
