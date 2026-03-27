import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../data/models/community_post.dart';
import '../../data/models/ranked_asset.dart';
import '../../theme/dopamine_theme.dart';
import '../asset/asset_detail_screen.dart';

/// 커뮤니티 피드·프로필 활동 등에서 동일한 게시 카드 UI
class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.locale,
    this.myUid,
    this.followingByUid,
    this.onToggleFollow,
    this.onToggleLike,
    this.onEditOwnPost,
    this.onDeleteOwnPost,
    this.showFollowButton = true,
    this.showLikeButton = true,
  });

  final CommunityPost post;
  final String locale;
  final String? myUid;
  final Map<String, bool>? followingByUid;
  final Future<void> Function(CommunityPost p)? onToggleFollow;
  final Future<void> Function(CommunityPost p)? onToggleLike;
  final void Function(CommunityPost p)? onEditOwnPost;
  final void Function(CommunityPost p)? onDeleteOwnPost;
  final bool showFollowButton;
  final bool showLikeButton;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final assetName = post.assetDisplayName?.trim();
    final timeStr = DateFormat.yMMMd(locale)
        .add_jm()
        .format(post.createdAt.toLocal());
    final showMenu =
        myUid != null &&
        post.authorUid == myUid &&
        onEditOwnPost != null &&
        onDeleteOwnPost != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (assetName != null && assetName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            assetName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: DopamineTheme.textPrimary,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: DopamineTheme.neonGreen.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: DopamineTheme.neonGreen.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Text(
                              post.assetSymbol,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: DopamineTheme.neonGreen,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _classBadge(post.assetClass, l10n),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: DopamineTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showMenu)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: DopamineTheme.textSecondary.withValues(alpha: 0.95),
                      size: 26,
                    ),
                    tooltip: l10n.communityMoreMenu,
                    onSelected: (v) {
                      if (v == 'edit') {
                        onEditOwnPost!(post);
                      } else if (v == 'delete') {
                        onDeleteOwnPost!(post);
                      }
                    },
                    itemBuilder: (ctx) => [
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
                    ],
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  tooltip: l10n.communityOpenAssetDetail,
                  icon: Icon(
                    Icons.info_outline_rounded,
                    color: DopamineTheme.neonGreen.withValues(alpha: 0.95),
                    size: 30,
                  ),
                  onPressed: () {
                    AssetDetailScreen.open(
                      context,
                      RankedAsset.communityShell(
                        symbol: post.assetSymbol,
                        assetClass: post.assetClass,
                        displayName: (assetName != null && assetName.isNotEmpty)
                            ? assetName
                            : null,
                      ),
                    );
                  },
                ),
              ],
            ),
            if (post.title != null && post.title!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                post.title!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: DopamineTheme.textPrimary,
                ),
              ),
            ],
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.imageUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (ctx, imgIdx) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.imageUrls[imgIdx],
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          width: 72,
                          height: 72,
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
              post.body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DopamineTheme.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    post.authorDisplayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: DopamineTheme.textSecondary,
                      fontWeight: FontWeight.w600,
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
            const SizedBox(height: 8),
            Row(
              children: [
                if (showFollowButton &&
                    onToggleFollow != null &&
                    myUid != null &&
                    post.authorUid != myUid) ...[
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor:
                          (followingByUid?[post.authorUid] ?? false)
                              ? DopamineTheme.textSecondary
                              : DopamineTheme.neonGreen,
                    ),
                    onPressed: () => onToggleFollow!(post),
                    child: Text(
                      (followingByUid?[post.authorUid] ?? false)
                          ? l10n.communityUnfollow
                          : l10n.communityFollow,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                if (showLikeButton && onToggleLike != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onToggleLike!(post),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          post.likedByMe
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 20,
                          color: post.likedByMe
                              ? DopamineTheme.accentRed
                              : DopamineTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.communityLikeCount(post.likeCount),
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
            if (post.replyCount > 0) ...[
              const SizedBox(height: 6),
              Text(
                l10n.communityReplyCount(post.replyCount),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: DopamineTheme.neonGreen.withValues(alpha: 0.9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
