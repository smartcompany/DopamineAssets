final class AssetComment {
  const AssetComment({
    required this.id,
    this.parentId,
    required this.body,
    this.title,
    this.imageUrls = const [],
    required this.authorUid,
    required this.authorDisplayName,
    required this.createdAt,
    this.likeCount = 0,
    this.likedByMe = false,
    this.assetSymbol,
    this.assetClass,
    this.assetDisplayName,
    this.moderationHiddenFromPublic = false,
  });

  final String id;
  final String? parentId;
  final String body;
  final String? title;
  final List<String> imageUrls;
  final String authorUid;
  final String authorDisplayName;
  final DateTime createdAt;
  final int likeCount;
  final bool likedByMe;
  /// GET 단건 등에서만 채워질 수 있음 (목록 응답에 없을 수 있음)
  final String? assetSymbol;
  final String? assetClass;
  final String? assetDisplayName;
  final bool moderationHiddenFromPublic;

  AssetComment copyWith({
    int? likeCount,
    bool? likedByMe,
    bool? moderationHiddenFromPublic,
  }) {
    return AssetComment(
      id: id,
      parentId: parentId,
      body: body,
      title: title,
      imageUrls: imageUrls,
      authorUid: authorUid,
      authorDisplayName: authorDisplayName,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      assetSymbol: assetSymbol,
      assetClass: assetClass,
      assetDisplayName: assetDisplayName,
      moderationHiddenFromPublic:
          moderationHiddenFromPublic ?? this.moderationHiddenFromPublic,
    );
  }

  factory AssetComment.fromJson(Map<String, dynamic> json) {
    final rawName = json['author_display_name'] as String?;
    final name = rawName == null || rawName.trim().isEmpty ? 'User' : rawName.trim();
    final rawUrls = json['image_urls'];
    final urls = rawUrls is List<dynamic>
        ? rawUrls.map((e) => e as String).toList()
        : const <String>[];
    final rawSym = json['asset_symbol'];
    final rawCls = json['asset_class'];
    final rawAdn = json['asset_display_name'];
    return AssetComment(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      body: json['body'] as String,
      title: json['title'] as String?,
      imageUrls: urls,
      authorUid: json['author_uid'] as String,
      authorDisplayName: name,
      createdAt: DateTime.parse(json['created_at'] as String),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
      assetSymbol: rawSym is String ? rawSym : null,
      assetClass: rawCls is String ? rawCls : null,
      assetDisplayName: rawAdn is String ? rawAdn : null,
      moderationHiddenFromPublic:
          json['moderation_hidden_from_public'] as bool? ?? false,
    );
  }
}
