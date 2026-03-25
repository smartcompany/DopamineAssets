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
    this.actorUid,
    this.actorDisplayName,
    this.likerUid,
    this.likerDisplayName,
    this.targetAuthorUid,
    this.targetAuthorDisplayName,
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
  final String? actorUid;
  final String? actorDisplayName;
  final String? likerUid;
  final String? likerDisplayName;
  final String? targetAuthorUid;
  final String? targetAuthorDisplayName;

  factory ProfileActivityItem.fromJson(Map<String, dynamic> json) {
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
      actorUid: json['actorUid'] as String?,
      actorDisplayName: json['actorDisplayName'] as String?,
      likerUid: json['likerUid'] as String?,
      likerDisplayName: json['likerDisplayName'] as String?,
      targetAuthorUid: json['targetAuthorUid'] as String?,
      targetAuthorDisplayName: json['targetAuthorDisplayName'] as String?,
    );
  }
}

final class ProfileUserRow {
  const ProfileUserRow({
    required this.uid,
    this.displayName,
  });

  final String uid;
  final String? displayName;

  factory ProfileUserRow.fromJson(Map<String, dynamic> json) {
    return ProfileUserRow(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String?,
    );
  }
}

final class ProfileStats {
  const ProfileStats({
    required this.postsCount,
    required this.followingCount,
    required this.followersCount,
  });

  final int postsCount;
  final int followingCount;
  final int followersCount;

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      postsCount: (json['postsCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
    );
  }
}
