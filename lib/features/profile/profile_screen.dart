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
import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../core/storage/community_post_image_upload.dart';
import '../../data/models/community_post.dart';
import '../../data/models/profile_activity_item.dart';
import '../../data/models/ranked_asset.dart';
import '../../theme/dopamine_theme.dart';
import '../asset/asset_detail_screen.dart';
import '../community/community_compose_screen.dart';
import '../community/community_post_card.dart';
import 'follow_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  StreamSubscription<User?>? _authSub;

  bool _loading = false;
  Object? _loadError;
  ProfileStats? _stats;
  List<ProfileActivityItem> _activity = const [];

  bool _savingName = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
      if (!mounted) return;
      if (u != null) {
        _syncNameField(u);
        _loadData();
      } else {
        setState(() {
          _stats = null;
          _activity = const [];
          _loadError = null;
          _loading = false;
          _nameController.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _syncNameField(User fb) {
    final n = fb.displayName?.trim();
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
      final url = await uploadCommunityPostImage(
        idToken: token,
        bytes: bytes,
        filename: 'avatar.$ext',
        contentType: _mimeForExt(ext),
      );
      await fb.updatePhotoURL(url);
      await fb.reload();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profilePhotoSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _removeProfilePhoto(AppLocalizations l10n) async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      await fb.updatePhotoURL(null);
      await fb.reload();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profilePhotoRemoved)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is FirebaseAuthException
          ? (e.message ?? e.code)
          : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _loadData() async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;

    _syncNameField(fb);

    final token = await fb.getIdToken();
    if (token == null || token.isEmpty) return;

    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final stats = await DopamineApi.fetchProfileStats(idToken: token);
      final act = await DopamineApi.fetchProfileActivity(idToken: token);
      if (!mounted) return;
      setState(() {
        _stats = stats;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorLoadFailed)),
      );
      return;
    }

    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;

    setState(() => _savingName = true);
    try {
      await fb.updateDisplayName(text);
      await fb.reload();
      final token = await fb.getIdToken();
      if (token != null && token.isNotEmpty) {
        await DopamineApi.patchProfileDisplayName(
          idToken: token,
          displayName: text,
        );
      }
      final u = FirebaseAuth.instance.currentUser!;
      final name = u.displayName?.trim();
      final email = u.email?.trim();
      final label = (name != null && name.isNotEmpty)
          ? name
          : (email != null && email.isNotEmpty)
              ? email
              : 'User';
      if (!mounted) return;
      context.read<AuthProvider<DopamineUser>>().setUserProfile(
            DopamineUser(uid: u.uid, displayName: label),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileDisplayNameSaved)),
      );
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
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    try {
      await u.delete();
      if (!context.mounted) return;
      await context.read<AuthProvider<DopamineUser>>().logout();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.profileDeleteDone)),
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'requires-recent-login') {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.profileRequiresRecentLogin)),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(e.message ?? e.code)),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await context.read<AuthProvider<DopamineUser>>().logout();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileLogoutDone)),
      );
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

  Future<void> _editOwnActivity(
    BuildContext context,
    ProfileActivityItem item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CommunityComposeScreen(
          editCommentId: item.commentId,
        ),
      ),
    );
    if (done == true && mounted) {
      await _loadData();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileActivityPostUpdated)),
      );
    }
  }

  ProfileActivityItem? _activityItemForCommentId(String commentId) {
    for (final a in _activity) {
      if (a.commentId == commentId) return a;
    }
    return null;
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
      await DopamineApi.toggleCommentLike(
        idToken: token,
        commentId: p.id,
      );
      if (!mounted) return;
      await _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorLoadFailed)),
      );
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
      await DopamineApi.deleteAssetComment(
        id: item.commentId,
        idToken: token,
      );
      if (!context.mounted) return;
      await _loadData();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileActivityPostDeleted)),
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
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
    final timeStr = DateFormat.yMMMd(locale)
        .add_jm()
        .format(item.at.toLocal());

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: Colors.white.withValues(alpha: 0.14),
      ),
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
        onTap: () => _openActivityItem(context, item),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    context.watch<AuthProvider<DopamineUser>>();
    final fb = FirebaseAuth.instance.currentUser;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navProfile),
      ),
      body: fb != null
          ? RefreshIndicator(
              color: DopamineTheme.neonGreen,
              onRefresh: _loadData,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  32 + homeShellBottomInset(context),
                ),
                children: [
                  Text(
                    l10n.profileSignedInSection,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: DopamineTheme.neonGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AccountProfilePhotoCard(
                    theme: theme,
                    l10n: l10n,
                    user: fb,
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
                  TextField(
                    controller: _nameController,
                    maxLength: 80,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: DopamineTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.profileDisplayNameHint,
                      hintStyle: TextStyle(
                        color: DopamineTheme.textSecondary.withValues(alpha: 0.85),
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      counterStyle: TextStyle(
                        color: DopamineTheme.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _savingName ? null : () => _saveDisplayName(l10n),
                      style: FilledButton.styleFrom(
                        backgroundColor: DopamineTheme.neonGreen,
                        foregroundColor: const Color(0xFF0A0A0A),
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
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
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
                  else if (_loadError != null)
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
                  else if (_stats != null)
                    _StatsRow(
                      stats: _stats!,
                      l10n: l10n,
                    ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.profileActivityTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: DopamineTheme.neonGreen,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_activity.isEmpty && !_loading && _loadError == null)
                    Text(
                      l10n.emptyState,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DopamineTheme.textSecondary,
                      ),
                    )
                  else
                    for (final item in _activity)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: item.hasCommunityCardPayload
                            ? CommunityPostCard(
                                post: item.toCommunityPost(
                                  authorUid: fb.uid,
                                  fallbackAuthorDisplayName:
                                      (fb.displayName?.trim().isNotEmpty ==
                                              true)
                                          ? fb.displayName!.trim()
                                          : 'User',
                                ),
                                locale: locale,
                                myUid: fb.uid,
                                showFollowButton: false,
                                followingByUid: null,
                                onToggleFollow: null,
                                onToggleLike: _toggleActivityLike,
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
                            : _buildActivityCard(
                                context,
                                theme,
                                l10n,
                                locale,
                                item,
                              ),
                      ),
                  const SizedBox(height: 28),
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
                  const SizedBox(height: 12),
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
    );
  }
}

/// 계정 영역 — 프로필 사진 카드 (글래스 톤 + 아이콘 액션)
class _AccountProfilePhotoCard extends StatelessWidget {
  const _AccountProfilePhotoCard({
    required this.theme,
    required this.l10n,
    required this.user,
    required this.uploadingPhoto,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final User user;
  final bool uploadingPhoto;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = user.photoURL?.trim().isNotEmpty == true;
    final borderGlow = DopamineTheme.neonGreen.withValues(alpha: 0.35);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.portrait_rounded,
                size: 20,
                color: DopamineTheme.neonGreen.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.profilePhotoTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: DopamineTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                          color: DopamineTheme.neonGreen.withValues(alpha: 0.12),
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
                        radius: 50,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.1),
                        child: ClipOval(
                          child: _profileAvatarChild(user),
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
          const SizedBox(height: 22),
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

  static Widget _profileAvatarChild(User user) {
    final url = user.photoURL?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
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
  const _StatsRow({
    required this.stats,
    required this.l10n,
  });

  final ProfileStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
                  builder: (_) => const FollowListScreen(
                    kind: FollowListKind.following,
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
                  builder: (_) => const FollowListScreen(
                    kind: FollowListKind.followers,
                  ),
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
  const _StatCell({
    required this.value,
    required this.label,
    this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: DopamineTheme.textPrimary,
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
