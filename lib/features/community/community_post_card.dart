import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import '../../core/time/relative_time_format.dart';
import '../../data/models/community_post.dart';
import '../../data/models/ranked_asset.dart';
import '../../theme/dopamine_theme.dart';
import '../../widgets/common_share_ui.dart';
import '../../widgets/community_translated_body.dart';
import '../asset/asset_detail_screen.dart';

/// 커뮤니티 피드·프로필 활동 등에서 동일한 게시 카드 UI
class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    this.myUid,
    this.onToggleLike,
    this.onEditOwnPost,
    this.onDeleteOwnPost,
    this.onReportPost,
    this.onBlockAuthor,
    this.onOpenAuthorProfile,
    this.onOpenPostDetail,
    this.showLikeButton = true,
    this.likeInProgress = false,
  });

  final CommunityPost post;
  final String? myUid;

  /// 좋아요 API 진행 중 — 하트 자리에 작은 프로그레스 표시·탭 비활성
  final bool likeInProgress;
  final Future<void> Function(CommunityPost p)? onToggleLike;
  final void Function(CommunityPost p)? onEditOwnPost;
  final void Function(CommunityPost p)? onDeleteOwnPost;
  final Future<void> Function(CommunityPost p)? onReportPost;
  final Future<void> Function(CommunityPost p)? onBlockAuthor;
  final void Function(CommunityPost p)? onOpenAuthorProfile;
  final void Function(CommunityPost p)? onOpenPostDetail;
  final bool showLikeButton;

  String _shareText(CommunityPost p) {
    final title = (p.title ?? '').trim();
    final body = p.body.trim();
    final assetName = (p.assetDisplayName ?? '').trim();
    final summary = body.isNotEmpty
        ? body.replaceAll('\n', ' ').trim()
        : '';
    final clipped = summary.length > 120
        ? '${summary.substring(0, 120)}...'
        : summary;
    final assetLine = assetName.isNotEmpty
        ? '$assetName (${p.assetSymbol})'
        : p.assetSymbol;
    return [
      if (title.isNotEmpty) title,
      if (clipped.isNotEmpty) clipped,
      '',
      'Asset: $assetLine',
      'Open in Dopamine Assets',
    ].join('\n');
  }

  Uri _shareUrl(CommunityPost p) => Uri(
        scheme: 'https',
        host: 'dopamine-assets.vercel.app',
        path: '/communityPost',
        queryParameters: {
          'postId': p.id,
          'from': 'share',
        },
      );

  Future<void> _sharePost(BuildContext context, CommunityPost p) async {
    await CommonShareUI.showShareOptionsDialog(
      context: context,
      shareText: _shareText(p),
      linkUrl: _shareUrl(p),
    );
  }

  String _classBadge(String assetClass, AppLocalizations l10n) {
    switch (assetClass) {
      case 'us_stock':
        return l10n.assetClassBadgeUsStock;
      case 'kr_stock':
        return l10n.assetClassBadgeKrStock;
      case 'jp_stock':
        return l10n.assetClassBadgeJpStock;
      case 'cn_stock':
        return l10n.assetClassBadgeCnStock;
      case 'crypto':
        return l10n.assetClassBadgeCrypto;
      case 'commodity':
        return l10n.assetClassBadgeCommodity;
      case 'theme':
        return l10n.assetClassBadgeTheme;
      default:
        return assetClass;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final assetName = post.assetDisplayName?.trim();
    final timeStr = formatRelativePostTime(post.createdAt, l10n.localeName);
    final isOwnPost = myUid != null && post.authorUid == myUid;
    final showOwnMenu =
        isOwnPost &&
        (onEditOwnPost != null || onDeleteOwnPost != null);
    final showLoggedInOtherMenu =
        myUid != null &&
        !isOwnPost &&
        (onReportPost != null || onBlockAuthor != null);
    final showGuestReportMenu =
        myUid == null && onReportPost != null;
    final showOverflowMenu =
        showOwnMenu || showLoggedInOtherMenu || showGuestReportMenu;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenPostDetail != null ? () => onOpenPostDetail!(post) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.moderationHiddenFromPublic &&
                  myUid != null &&
                  post.authorUid == myUid) ...[
                _ModerationHiddenBanner(
                  text: l10n.communityPostHiddenByReportNotice,
                ),
                const SizedBox(height: 10),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (assetName != null && assetName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
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
                          displayName:
                              (assetName != null && assetName.isNotEmpty)
                              ? assetName
                              : null,
                        ),
                      );
                    },
                  ),
                  if (showOverflowMenu)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: DopamineTheme.textSecondary.withValues(
                          alpha: 0.95,
                        ),
                        size: 26,
                      ),
                      tooltip: l10n.communityMoreMenu,
                      onSelected: (v) async {
                        if (v == 'edit') {
                          onEditOwnPost?.call(post);
                        } else if (v == 'delete') {
                          onDeleteOwnPost?.call(post);
                        } else if (v == 'report') {
                          await onReportPost?.call(post);
                        } else if (v == 'block') {
                          await onBlockAuthor?.call(post);
                        }
                      },
                      itemBuilder: (ctx) {
                        if (showOwnMenu) {
                          return [
                            if (onEditOwnPost != null)
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(l10n.profileActivityEditPost),
                              ),
                            if (onDeleteOwnPost != null)
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  l10n.profileActivityDeletePost,
                                  style: TextStyle(
                                    color: Theme.of(ctx).colorScheme.error,
                                  ),
                                ),
                              ),
                          ];
                        }
                        if (showGuestReportMenu) {
                          return [
                            PopupMenuItem(
                              value: 'report',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flag_outlined,
                                    size: 20,
                                    color: DopamineTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(l10n.communityReportPostShort),
                                ],
                              ),
                            ),
                          ];
                        }
                        return [
                          if (onReportPost != null)
                            PopupMenuItem(
                              value: 'report',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flag_outlined,
                                    size: 20,
                                    color: DopamineTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(l10n.communityReportPostShort),
                                ],
                              ),
                            ),
                          if (onBlockAuthor != null)
                            PopupMenuItem(
                              value: 'block',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_off_outlined,
                                    size: 20,
                                    color: Theme.of(ctx).colorScheme.error,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    l10n.communityBlockAuthorShort,
                                    style: TextStyle(
                                      color: Theme.of(ctx).colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ];
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
                const SizedBox(height: 6),
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
              const SizedBox(height: 8),
              CommunityTranslatedBody(
                body: post.body,
                localeName: l10n.localeName,
                showOriginalLabel: l10n.communityShowOriginal,
                showTranslatedLabel: l10n.communityShowTranslated,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DopamineTheme.textPrimary,
                  height: 1.32,
                ),
                maxLines: 4,
                seeMoreLabel: l10n.communityPostSeeMore,
                onSeeMore: onOpenPostDetail != null
                    ? () => onOpenPostDetail!(post)
                    : null,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: onOpenAuthorProfile != null
                          ? () => onOpenAuthorProfile!(post)
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            post.authorDisplayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: DopamineTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _AuthorAvatar(
                            photoUrl: post.authorPhotoUrl,
                            name: post.authorDisplayName,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((showLikeButton && onToggleLike != null) ||
                          onOpenPostDetail != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showLikeButton && onToggleLike != null)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: likeInProgress
                                    ? null
                                    : () => onToggleLike!(post),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: likeInProgress
                                          ? const Center(
                                              child: SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: DopamineTheme
                                                          .neonGreen,
                                                    ),
                                              ),
                                            )
                                          : Icon(
                                              post.likedByMe
                                                  ? Icons.favorite_rounded
                                                  : Icons
                                                        .favorite_border_rounded,
                                              size: 20,
                                              color: post.likedByMe
                                                  ? DopamineTheme.accentRed
                                                  : DopamineTheme.textSecondary,
                                            ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.communityLikeCount(post.likeCount),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: DopamineTheme.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            if (onOpenPostDetail != null) ...[
                              if (showLikeButton && onToggleLike != null)
                                const SizedBox(width: 14),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => onOpenPostDetail!(post),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 20,
                                      color: DopamineTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.communityCommentCount(
                                        post.replyCount,
                                      ),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: DopamineTheme.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _sharePost(context, post),
                                child: Icon(
                                  Icons.share_outlined,
                                  size: 20,
                                  color: DopamineTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      if ((showLikeButton && onToggleLike != null) ||
                          onOpenPostDetail != null)
                        const SizedBox(height: 3),
                      Text(
                        timeStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: DopamineTheme.textSecondary.withValues(
                            alpha: 0.88,
                          ),
                          fontSize: 11.5,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModerationHiddenBanner extends StatelessWidget {
  const _ModerationHiddenBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.amber.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.visibility_off_outlined,
              size: 20,
              color: Colors.amber.shade700,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.35,
                  color: DopamineTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.photoUrl, required this.name});

  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _AuthorAvatarPlaceholder(name: name),
        ),
      );
    }
    return _AuthorAvatarPlaceholder(name: name);
  }
}

class _AuthorAvatarPlaceholder extends StatelessWidget {
  const _AuthorAvatarPlaceholder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = name.trim();
    final letter = t.isEmpty ? '?' : String.fromCharCode(t.runes.first);
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      child: Text(
        letter.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: DopamineTheme.textSecondary,
        ),
      ),
    );
  }
}
