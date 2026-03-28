import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/models/profile_activity_item.dart';
import '../../theme/dopamine_theme.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key, this.onListChanged});

  /// 차단 해제 후 프로필 통계 등 갱신
  final VoidCallback? onListChanged;

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  bool _loading = true;
  Object? _error;
  List<ProfileUserRow> _items = const [];
  final Set<String> _unblocking = {};

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
      final list = await DopamineApi.fetchProfileBlockedUsers(idToken: token);
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

  Future<void> _unblock(ProfileUserRow r) async {
    final l10n = AppLocalizations.of(context)!;
    final uid = r.uid;
    if (_unblocking.contains(uid)) return;

    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    final token = await fb.getIdToken();
    if (token == null || token.isEmpty || !mounted) return;

    setState(() => _unblocking.add(uid));
    try {
      await DopamineApi.unblockUser(idToken: token, targetUid: uid);
      if (!mounted) return;
      setState(() {
        _items = _items.where((x) => x.uid != uid).toList();
        _unblocking.remove(uid);
      });
      widget.onListChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileUnblockedDone)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _unblocking.remove(uid));
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileBlockedTitle)),
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
                        l10n.profileBlockedListEmpty,
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
                        final busy = _unblocking.contains(r.uid);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          title: Text(
                            _label(r),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: DopamineTheme.textPrimary,
                            ),
                          ),
                          trailing: TextButton(
                            onPressed: busy ? null : () => _unblock(r),
                            child: busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: DopamineTheme.neonGreen,
                                    ),
                                  )
                                : Text(
                                    l10n.profileUnblockAction,
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
    );
  }
}
