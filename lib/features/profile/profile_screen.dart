import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import '../../auth/dopamine_user.dart';
import '../../auth/present_dopamine_auth_screen.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/models/profile_activity_item.dart';
import '../../data/models/ranked_asset.dart';
import '../../theme/dopamine_theme.dart';
import '../asset/asset_detail_screen.dart';
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

    if (item.kind == 'my_post') {
      final rawName = item.assetDisplayName?.trim();
      final displayName =
          rawName != null && rawName.isNotEmpty ? rawName : item.assetSymbol;
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
                  l10n.profileActivityPostOnAsset(displayName),
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 17,
                      color:
                          DopamineTheme.textSecondary.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.likeCount ?? 0}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: DopamineTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 17,
                      color:
                          DopamineTheme.textSecondary.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.replyCount ?? 0}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: DopamineTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(
                    l10n.profileSignedInSection,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: DopamineTheme.neonGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  _InfoTile(
                    label: l10n.profileEmail,
                    value: fb.email ?? l10n.profileNoEmail,
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
                        child: _buildActivityCard(
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: DopamineTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: DopamineTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
