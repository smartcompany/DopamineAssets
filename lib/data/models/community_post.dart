final class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.body,
    this.title,
    this.imageUrls = const [],
    required this.authorUid,
    required this.authorDisplayName,
    required this.createdAt,
    required this.assetSymbol,
    required this.assetClass,
    this.assetDisplayName,
    required this.replyCount,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String body;
  final String? title;
  final List<String> imageUrls;
  final String authorUid;
  final String authorDisplayName;
  final DateTime createdAt;
  final String assetSymbol;
  final String assetClass;
  /// 글 작성 시 저장한 종목 표시명(없으면 랭킹·심볼만으로 표시)
  final String? assetDisplayName;
  final int replyCount;
  final int likeCount;
  final bool likedByMe;

  CommunityPost copyWith({
    int? likeCount,
    bool? likedByMe,
  }) {
    return CommunityPost(
      id: id,
      body: body,
      title: title,
      imageUrls: imageUrls,
      authorUid: authorUid,
      authorDisplayName: authorDisplayName,
      createdAt: createdAt,
      assetSymbol: assetSymbol,
      assetClass: assetClass,
      assetDisplayName: assetDisplayName,
      replyCount: replyCount,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final rawName = json['author_display_name'] as String?;
    final name =
        rawName == null || rawName.trim().isEmpty ? 'User' : rawName.trim();
    final rawUrls = json['image_urls'];
    final urls = rawUrls is List<dynamic>
        ? rawUrls.map((e) => e as String).toList()
        : const <String>[];
    return CommunityPost(
      id: json['id'] as String,
      body: json['body'] as String,
      title: json['title'] as String?,
      imageUrls: urls,
      authorUid: json['author_uid'] as String,
      authorDisplayName: name,
      createdAt: DateTime.parse(json['created_at'] as String),
      assetSymbol: json['asset_symbol'] as String,
      assetClass: json['asset_class'] as String,
      assetDisplayName: json['asset_display_name'] as String?,
      replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
    );
  }
}
