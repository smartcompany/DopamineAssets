import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/models/profile_activity_item.dart';
import '../../theme/dopamine_theme.dart';
import 'public_profile_screen.dart';

enum FollowListKind { following, followers }

class FollowListScreen extends StatefulWidget {
  const FollowListScreen({
    super.key,
    required this.kind,
    this.onListChanged,
  });

  final FollowListKind kind;

  /// 팔로잉에서 언팔로우 후 프로필 통계 갱신 등
  final VoidCallback? onListChanged;

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  bool _loading = true;
  Object? _error;
  List<ProfileUserRow> _items = const [];
  final Set<String> _unfollowing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) {
      setState(() {
        _loading = false;
        _error = 'auth';
      });
      return;
    }
    final token = await fb.getIdToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'auth';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = widget.kind == FollowListKind.following
          ? await DopamineApi.fetchProfileFollowing(idToken: token)
          : await DopamineApi.fetchProfileFollowers(idToken: token);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  String _label(ProfileUserRow r) {
    final n = r.displayName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'User';
  }

  void _openProfile(ProfileUserRow r) {
    final name = _label(r);
    PublicProfileScreen.open(
      context,
      authorUid: r.uid,
      authorName: name,
      authorPhotoUrl: r.photoUrl,
    );
  }

  Future<void> _unfollow(ProfileUserRow r) async {
    final l10n = AppLocalizations.of(context)!;
    final uid = r.uid;
    if (_unfollowing.contains(uid)) return;

    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    final token = await fb.getIdToken();
    if (token == null || token.isEmpty || !mounted) return;

    setState(() => _unfollowing.add(uid));
    try {
      await DopamineApi.unfollowUser(idToken: token, targetUid: uid);
      if (!mounted) return;
      setState(() {
        _items = _items.where((x) => x.uid != uid).toList();
        _unfollowing.remove(uid);
      });
      widget.onListChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _unfollowing.remove(uid));
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = widget.kind == FollowListKind.following
        ? l10n.profileFollowTitleFollowing
        : l10n.profileFollowTitleFollowers;
    final showUnfollow = widget.kind == FollowListKind.following;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: DopamineTheme.neonGreen,
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error is ApiException
                              ? (_error as ApiException).message
                              : l10n.errorLoadFailed,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: DopamineTheme.accentRed,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Text(
                        l10n.profileFollowListEmpty,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: DopamineTheme.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      itemBuilder: (context, i) {
                        final r = _items[i];
                        final name = _label(r);
                        final busy = _unfollowing.contains(r.uid);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _openProfile(r),
                                  customBorder: const CircleBorder(),
                                  child: _FollowListAvatar(
                                    name: name,
                                    photoUrl: r.photoUrl,
                                    radius: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: DopamineTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (showUnfollow) ...[
                                const SizedBox(width: 8),
                                busy
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: Padding(
                                          padding: EdgeInsets.all(4),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: DopamineTheme.neonGreen,
                                          ),
                                        ),
                                      )
                                    : TextButton(
                                        onPressed: () => _unfollow(r),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              DopamineTheme.textSecondary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: Text(
                                          l10n.profileFollowUnfollow,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

class _FollowListAvatar extends StatelessWidget {
  const _FollowListAvatar({
    required this.name,
    required this.photoUrl,
    required this.radius,
  });

  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _FollowListAvatarFallback(radius: radius),
        ),
      );
    }
    return _FollowListAvatarFallback(radius: radius);
  }
}

class _FollowListAvatarFallback extends StatelessWidget {
  const _FollowListAvatarFallback({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white.withValues(alpha: 0.12),
      child: Icon(
        Icons.person_rounded,
        size: radius * 1.15,
        color: DopamineTheme.textSecondary,
      ),
    );
  }
}
