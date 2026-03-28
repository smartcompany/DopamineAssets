import 'community_post.dart';

final class ProfileActivityItem {
  const ProfileActivityItem({
    required this.kind,
    required this.at,
    required this.commentId,
    required this.bodyPreview,
    required this.assetSymbol,
    required this.assetClass,
    this.assetDisplayName,
    this.likeCount,
    this.replyCount,
    this.body,
    this.title,
    this.imageUrls,
    this.postAuthorDisplayName,
    this.likedByMe,
    this.actorUid,
    this.actorDisplayName,
    this.likerUid,
    this.likerDisplayName,
    this.targetAuthorUid,
    this.targetAuthorDisplayName,
    this.moderationHiddenFromPublic,
  });

  final String kind;
  final DateTime at;
  final String commentId;
  final String bodyPreview;
  final String assetSymbol;
  final String assetClass;
  /// my_post — 서버에서 Yahoo 등으로 채운 종목명
  final String? assetDisplayName;
  final int? likeCount;
  final int? replyCount;
  /// my_post / my_reply — 커뮤니티 카드용 전체 본문
  final String? body;
  final String? title;
  final List<String>? imageUrls;
  final String? postAuthorDisplayName;
  final bool? likedByMe;
  final String? actorUid;
  final String? actorDisplayName;
  final String? likerUid;
  final String? likerDisplayName;
  final String? targetAuthorUid;
  final String? targetAuthorDisplayName;
  final bool? moderationHiddenFromPublic;

  factory ProfileActivityItem.fromJson(Map<String, dynamic> json) {
    final rawUrls = json['imageUrls'];
    final urls = rawUrls is List<dynamic>
        ? rawUrls.map((e) => e as String).toList()
        : null;
    return ProfileActivityItem(
      kind: json['kind'] as String,
      at: DateTime.parse(json['at'] as String),
      commentId: json['commentId'] as String,
      bodyPreview: json['bodyPreview'] as String? ?? '',
      assetSymbol: json['assetSymbol'] as String,
      assetClass: json['assetClass'] as String,
      assetDisplayName: json['assetDisplayName'] as String?,
      likeCount: (json['likeCount'] as num?)?.toInt(),
      replyCount: (json['replyCount'] as num?)?.toInt(),
      body: json['body'] as String?,
      title: json['title'] as String?,
      imageUrls: urls,
      postAuthorDisplayName: json['postAuthorDisplayName'] as String?,
      likedByMe: json['likedByMe'] as bool?,
      actorUid: json['actorUid'] as String?,
      actorDisplayName: json['actorDisplayName'] as String?,
      likerUid: json['likerUid'] as String?,
      likerDisplayName: json['likerDisplayName'] as String?,
      targetAuthorUid: json['targetAuthorUid'] as String?,
      targetAuthorDisplayName: json['targetAuthorDisplayName'] as String?,
      moderationHiddenFromPublic: json['moderationHiddenFromPublic'] as bool?,
    );
  }
}

final class ProfileUserRow {
  const ProfileUserRow({
    required this.uid,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String? displayName;
  final String? photoUrl;

  factory ProfileUserRow.fromJson(Map<String, dynamic> json) {
    return ProfileUserRow(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}

final class ProfileStats {
  const ProfileStats({
    required this.postsCount,
    required this.followingCount,
    required this.followersCount,
    this.blockedCount = 0,
  });

  final int postsCount;
  final int followingCount;
  final int followersCount;
  final int blockedCount;

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      postsCount: (json['postsCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      blockedCount: (json['blockedCount'] as num?)?.toInt() ?? 0,
    );
  }
}

extension ProfileActivityItemCommunity on ProfileActivityItem {
  bool get hasCommunityCardPayload {
    if (kind != 'my_post' && kind != 'my_reply') return false;
    final b = body;
    return b != null && b.trim().isNotEmpty;
  }

  CommunityPost toCommunityPost({
    required String authorUid,
    required String fallbackAuthorDisplayName,
    String? authorPhotoUrl,
  }) {
    final b = body;
    if (b == null || b.trim().isEmpty) {
      throw ArgumentError('ProfileActivityItem missing body for card');
    }
    final name = postAuthorDisplayName?.trim();
    return CommunityPost(
      id: commentId,
      body: b,
      title: title,
      imageUrls: imageUrls ?? const [],
      authorUid: authorUid,
      authorDisplayName:
          name != null && name.isNotEmpty ? name : fallbackAuthorDisplayName,
      authorPhotoUrl: authorPhotoUrl,
      createdAt: at,
      assetSymbol: assetSymbol,
      assetClass: assetClass,
      assetDisplayName: assetDisplayName,
      replyCount: replyCount ?? 0,
      likeCount: likeCount ?? 0,
      likedByMe: likedByMe ?? false,
      moderationHiddenFromPublic: moderationHiddenFromPublic ?? false,
    );
  }
}
