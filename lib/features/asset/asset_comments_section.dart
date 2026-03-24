import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import '../../auth/dopamine_auth_config.dart';
import '../../auth/dopamine_user.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/models/asset_comment.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/dopamine_theme.dart';

class AssetCommentsSection extends StatefulWidget {
  const AssetCommentsSection({
    super.key,
    required this.symbol,
    required this.assetClass,
  });

  /// 상세 API([AssetDetail]) 기준 — 리스트의 [RankedAsset.assetClass]가 비어 있어도 댓글 스레드가 동작하도록 함.
  final String symbol;
  final String assetClass;

  @override
  State<AssetCommentsSection> createState() => _AssetCommentsSectionState();
}

class _FlatRow {
  _FlatRow(this.comment, this.depth);
  final AssetComment comment;
  final int depth;
}

class _AssetCommentsSectionState extends State<AssetCommentsSection> {
  late Future<List<AssetComment>> _future;
  final _controller = TextEditingController();
  String? _replyParentId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(AssetCommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol ||
        oldWidget.assetClass != widget.assetClass) {
      setState(() {
        _future = _load();
      });
    }
  }

  Future<List<AssetComment>> _load() {
    return DopamineApi.fetchAssetComments(
      symbol: widget.symbol,
      assetClass: widget.assetClass,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_FlatRow> _flatten(List<AssetComment> flat) {
    final byParent = <String?, List<AssetComment>>{};
    for (final c in flat) {
      byParent.putIfAbsent(c.parentId, () => []).add(c);
    }
    for (final list in byParent.values) {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    final out = <_FlatRow>[];
    void walk(String? parentId, int depth) {
      final kids = byParent[parentId] ?? const <AssetComment>[];
      for (final c in kids) {
        out.add(_FlatRow(c, depth));
        walk(c.id, depth + 1);
      }
    }

    walk(null, 0);
    return out;
  }

  Future<void> _openAuth(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => AuthScreen<DopamineUser>(
          config: dopamineAuthConfig(),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _submit(BuildContext context, AppLocalizations l10n) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) {
      await _openAuth(context);
      return;
    }

    setState(() => _submitting = true);
    try {
      final token = await fb.getIdToken();
      if (token == null || token.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.assetCommentsSendError)),
          );
        }
        return;
      }
      await DopamineApi.postAssetComment(
        symbol: widget.symbol,
        assetClass: widget.assetClass,
        body: text,
        parentId: _replyParentId,
        idToken: token,
      );
      _controller.clear();
      _replyParentId = null;
      await _reload();
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is ApiException ? e.message : l10n.assetCommentsSendError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    context.watch<AuthProvider<DopamineUser>>();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.assetCommentsTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: DopamineTheme.neonGreen,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<AssetComment>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DopamineTheme.neonGreen,
                        ),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      Text(
                        l10n.errorLoadFailed,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: DopamineTheme.accentRed,
                        ),
                      ),
                      TextButton(
                        onPressed: _reload,
                        child: Text(l10n.retry),
                      ),
                    ],
                  );
                }
                final items = snapshot.data ?? const <AssetComment>[];
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.assetCommentsEmpty,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DopamineTheme.textSecondary,
                      ),
                    ),
                  );
                }
                final rows = _flatten(items);
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    final c = row.comment;
                    final locale = Localizations.localeOf(context).toLanguageTag();
                    final timeStr = DateFormat.yMMMd(locale).add_jm().format(c.createdAt.toLocal());
                    return Padding(
                      padding: EdgeInsets.only(left: row.depth * 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.authorDisplayName,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: DopamineTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
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
                          const SizedBox(height: 4),
                          Text(
                            c.body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: DopamineTheme.textPrimary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: DopamineTheme.neonGreen,
                            ),
                            onPressed: () {
                              setState(() {
                                _replyParentId = c.id;
                              });
                            },
                            child: Text(l10n.assetCommentsReply),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            if (_replyParentId != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.assetCommentsReplying,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: DopamineTheme.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _replyParentId = null),
                    child: Text(
                      l10n.assetCommentsCancelReply,
                      style: const TextStyle(color: DopamineTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              maxLines: 4,
              maxLength: 2000,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DopamineTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: l10n.assetCommentsPlaceholder,
                hintStyle: TextStyle(
                  color: DopamineTheme.textSecondary.withValues(alpha: 0.85),
                ),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.25),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: DopamineTheme.neonGreen,
                    width: 1.2,
                  ),
                ),
                counterStyle: TextStyle(
                  color: DopamineTheme.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _submitting
                  ? null
                  : () => _submit(context, l10n),
              style: FilledButton.styleFrom(
                backgroundColor: DopamineTheme.neonGreen,
                foregroundColor: const Color(0xFF0A0A0A),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0A0A0A),
                      ),
                    )
                  : Text(l10n.assetCommentsPost),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }
}
