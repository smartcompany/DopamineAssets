import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';

import '../../core/navigation/home_shell_bottom_inset.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/models/community_post.dart';
import '../../theme/dopamine_theme.dart';
import '../../auth/present_dopamine_auth_screen.dart';
import '../community/community_post_card.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    super.key,
    required this.authorUid,
    required this.authorName,
    this.authorPhotoUrl,
  });

  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;

  static Future<void> open(
    BuildContext context, {
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicProfileScreen(
          authorUid: authorUid,
          authorName: authorName,
          authorPhotoUrl: authorPhotoUrl,
        ),
      ),
    );
  }

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _loading = true;
  bool _working = false;
  Object? _error;
  String _displayName = '';
  String? _photoUrl;
  int _postsCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isFollowing = false;
  bool _blockedByMe = false;
  List<CommunityPost> _posts = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<String?> _idTokenOrLogin() async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) {
      await presentDopamineAuthScreen(context);
      final next = FirebaseAuth.instance.currentUser;
      return next?.getIdToken();
    }
    return fb.getIdToken();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String? token;
      final fb = FirebaseAuth.instance.currentUser;
      if (fb != null) {
        token = await fb.getIdToken();
      }
      final results = await Future.wait<dynamic>([
        DopamineApi.fetchPublicProfile(
          uid: widget.authorUid,
          idToken: token,
        ),
        DopamineApi.fetchCommunityPosts(
          sort: 'latest',
          authorUid: widget.authorUid,
          idToken: token,
        ),
      ]);
      final profile = results[0] as Map<String, dynamic>;
      final items = results[1] as List<CommunityPost>;
      if (!mounted) return;
      setState(() {
        _displayName = (profile['displayName'] as String?)?.trim().isNotEmpty == true
            ? (profile['displayName'] as String).trim()
            : widget.authorName;
        _photoUrl = (profile['photoUrl'] as String?)?.trim();
        _postsCount = (profile['postsCount'] as num?)?.toInt() ?? 0;
        _followersCount = (profile['followersCount'] as num?)?.toInt() ?? 0;
        _followingCount = (profile['followingCount'] as num?)?.toInt() ?? 0;
        _isFollowing = profile['isFollowing'] as bool? ?? false;
        _blockedByMe = profile['blockedByMe'] as bool? ?? false;
        _posts = items;
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

  Future<void> _toggleFollow() async {
    final token = await _idTokenOrLogin();
    if (token == null || !mounted) return;
    if (_working) return;
    setState(() => _working = true);
    try {
      if (_isFollowing) {
        await DopamineApi.unfollowUser(idToken: token, targetUid: widget.authorUid);
      } else {
        await DopamineApi.followUser(idToken: token, targetUid: widget.authorUid);
      }
      if (!mounted) return;
      await _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadFailed)),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _toggleBlock() async {
    final token = await _idTokenOrLogin();
    if (token == null || !mounted) return;
    if (_working) return;
    setState(() => _working = true);
    try {
      if (_blockedByMe) {
        await DopamineApi.unblockUser(idToken: token, targetUid: widget.authorUid);
      } else {
        await DopamineApi.blockUser(idToken: token, targetUid: widget.authorUid);
      }
      if (!mounted) return;
      await _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadFailed)),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_displayName.isNotEmpty ? _displayName : widget.authorName),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _AuthorAvatar(
                      name: _displayName.isNotEmpty ? _displayName : widget.authorName,
                      photoUrl: _photoUrl ?? widget.authorPhotoUrl,
                      radius: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _displayName.isNotEmpty ? _displayName : widget.authorName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: DopamineTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _CountStat(label: '게시글', value: _postsCount),
                    ),
                    Expanded(
                      child: _CountStat(label: l10n.profileStatFollowers, value: _followersCount),
                    ),
                    Expanded(
                      child: _CountStat(label: l10n.profileStatFollowing, value: _followingCount),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: (_working || _blockedByMe) ? null : _toggleFollow,
                        child: Text(_isFollowing ? l10n.communityUnfollow : l10n.communityFollow),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _working ? null : _toggleBlock,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _blockedByMe
                              ? DopamineTheme.textSecondary
                              : DopamineTheme.accentRed,
                          side: BorderSide(
                            color: (_blockedByMe
                                    ? DopamineTheme.textSecondary
                                    : DopamineTheme.accentRed)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(_blockedByMe ? '차단 해제' : '차단'),
                      ),
                    ),
                  ],
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
                if (_error != null) {
                  final message = _error is ApiException
                      ? (_error as ApiException).message
                      : l10n.errorLoadFailed;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: DopamineTheme.accentRed,
                        ),
                      ),
                    ),
                  );
                }
                if (_posts.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.emptyState,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DopamineTheme.textSecondary,
                      ),
                    ),
                  );
                }
                final locale = Localizations.localeOf(context).toLanguageTag();
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    20 + homeShellBottomInset(context),
                  ),
                  itemCount: _posts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return CommunityPostCard(
                      post: _posts[index],
                      locale: locale,
                      myUid: FirebaseAuth.instance.currentUser?.uid,
                      showFollowButton: false,
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

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({
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
              _AuthorAvatarFallback(name: name, radius: radius),
        ),
      );
    }
    return _AuthorAvatarFallback(name: name, radius: radius);
  }
}

class _AuthorAvatarFallback extends StatelessWidget {
  const _AuthorAvatarFallback({
    required this.name,
    required this.radius,
  });

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = name.trim();
    final letter = t.isEmpty ? '?' : String.fromCharCode(t.runes.first);
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white.withValues(alpha: 0.12),
      child: Text(
        letter.toUpperCase(),
        style: theme.textTheme.titleMedium?.copyWith(
          color: DopamineTheme.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CountStat extends StatelessWidget {
  const _CountStat({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '$value',
          style: theme.textTheme.titleMedium?.copyWith(
            color: DopamineTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: DopamineTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
