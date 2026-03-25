import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/models/profile_activity_item.dart';
import '../../theme/dopamine_theme.dart';

enum FollowListKind { following, followers }

class FollowListScreen extends StatefulWidget {
  const FollowListScreen({super.key, required this.kind});

  final FollowListKind kind;

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  bool _loading = true;
  Object? _error;
  List<ProfileUserRow> _items = const [];

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = widget.kind == FollowListKind.following
        ? l10n.profileFollowTitleFollowing
        : l10n.profileFollowTitleFollowers;

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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      itemBuilder: (context, i) {
                        final r = _items[i];
                        return ListTile(
                          title: Text(
                            _label(r),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: DopamineTheme.textPrimary,
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
