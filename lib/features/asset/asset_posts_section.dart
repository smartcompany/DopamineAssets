import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import '../../auth/dopamine_community_profile_gate.dart';
import '../../auth/dopamine_user.dart';
import '../../core/navigation/home_shell_navigation.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/models/asset_comment.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/dopamine_theme.dart';

class AssetPostsSection extends StatefulWidget {
  const AssetPostsSection({
    super.key,
    required this.symbol,
    required this.assetClass,
    this.displayName,
  });

  final String symbol;
  final String assetClass;
  final String? displayName;

  @override
  State<AssetPostsSection> createState() => _AssetPostsSectionState();
}

class _AssetPostsSectionState extends State<AssetPostsSection> {
  List<AssetComment>? _comments;
  Object? _loadError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(AssetPostsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol ||
        oldWidget.assetClass != widget.assetClass) {
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final fb = FirebaseAuth.instance.currentUser;
    final token = await fb?.getIdToken();
    try {
      final list = await DopamineApi.fetchAssetComments(
        symbol: widget.symbol,
        assetClass: widget.assetClass,
        idToken: token,
      );
      if (!mounted) return;
      setState(() {
        _comments = list;
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

  /// 가장 최근 루트 게시글(또는 루트가 없으면 전체 중 최신 1건)을 미리보기로 씁니다.
  AssetComment? _previewComment(List<AssetComment> items) {
    if (items.isEmpty) return null;
    final roots = items.where((c) => c.parentId == null).toList();
    if (roots.isEmpty) {
      final sorted = List<AssetComment>.from(items)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted.first;
    }
    roots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return roots.first;
  }

  void _openCommunity(BuildContext context) {
    context.read<HomeShellNavigation>().openCommunityForAsset(
          symbol: widget.symbol,
          assetClass: widget.assetClass,
          displayName: widget.displayName,
        );
    Navigator.of(context).pop();
  }

  Future<void> _toggleLike(int index, AssetComment c) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await ensureCommunityIdentity(context, showLoginHintSnack: true)) {
      return;
    }
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null || !mounted) return;
    final token = await fb.getIdToken();
    if (token == null || !mounted) return;
    try {
      final r = await DopamineApi.toggleCommentLike(
        idToken: token,
        commentId: c.id,
      );
      if (!mounted || _comments == null) return;
      setState(() {
        final next = List<AssetComment>.from(_comments!);
        next[index] = c.copyWith(
          likeCount: r.likeCount,
          likedByMe: r.liked,
        );
        _comments = next;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.assetPostsSendError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider<DopamineUser>>();

    final card = _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.assetPostsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: DopamineTheme.neonGreen,
            ),
          ),
          const SizedBox(height: 4),
          Builder(
            builder: (context) {
              if (_loading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
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
              if (_loadError != null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
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
              final items = _comments ?? const <AssetComment>[];
              final preview = _previewComment(items);
              if (preview == null) {
                return Text(
                  l10n.assetPostsEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: DopamineTheme.textSecondary,
                  ),
                );
              }
              final flatIndex = items.indexWhere((x) => x.id == preview.id);
              final locale = Localizations.localeOf(context).toLanguageTag();
              final timeStr = DateFormat.yMMMd(locale)
                  .add_jm()
                  .format(preview.createdAt.toLocal());
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    preview.authorDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: DopamineTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DopamineTheme.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          timeStr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: DopamineTheme.textSecondary,
                          ),
                        ),
                      ),
                      if (auth.isLoggedIn())
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: flatIndex < 0
                              ? null
                              : () => _toggleLike(flatIndex, preview),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  preview.likedByMe
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 18,
                                  color: preview.likedByMe
                                      ? DopamineTheme.accentRed
                                      : DopamineTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${preview.likeCount}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: DopamineTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: _loading
          ? card
          : Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openCommunity(context),
                borderRadius: BorderRadius.circular(20),
                child: card,
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
