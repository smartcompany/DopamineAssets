final class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.body,
    this.title,
    this.imageUrls = const [],
    required this.authorUid,
    required this.authorDisplayName,
    this.authorPhotoUrl,
    required this.createdAt,
    required this.assetSymbol,
    required this.assetClass,
    this.assetDisplayName,
    required this.replyCount,
    this.likeCount = 0,
    this.likedByMe = false,
    this.moderationHiddenFromPublic = false,
  });

  final String id;
  final String body;
  final String? title;
  final List<String> imageUrls;
  final String authorUid;
  final String authorDisplayName;
  /// 프로필 사진 URL (없으면 플레이스홀더)
  final String? authorPhotoUrl;
  final DateTime createdAt;
  final String assetSymbol;
  final String assetClass;
  /// 글 작성 시 저장한 종목 표시명(없으면 랭킹·심볼만으로 표시)
  final String? assetDisplayName;
  final int replyCount;
  final int likeCount;
  final bool likedByMe;
  /// 신고 등으로 타인에게 비노출(작성자 본인은 열람·활동 목록 가능)
  final bool moderationHiddenFromPublic;

  CommunityPost copyWith({
    String? authorDisplayName,
    int? likeCount,
    bool? likedByMe,
    bool? moderationHiddenFromPublic,
  }) {
    return CommunityPost(
      id: id,
      body: body,
      title: title,
      imageUrls: imageUrls,
      authorUid: authorUid,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorPhotoUrl: authorPhotoUrl,
      createdAt: createdAt,
      assetSymbol: assetSymbol,
      assetClass: assetClass,
      assetDisplayName: assetDisplayName,
      replyCount: replyCount,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      moderationHiddenFromPublic:
          moderationHiddenFromPublic ?? this.moderationHiddenFromPublic,
    );
  }

  /// 푸시 딥링크 등: 루트 [AssetComment] 응답을 목록용 게시글 모델로 변환합니다.
  factory CommunityPost.fromRootAssetComment({
    required String id,
    required String body,
    String? title,
    List<String> imageUrls = const [],
    required String authorUid,
    required String authorDisplayName,
    String? authorPhotoUrl,
    required DateTime createdAt,
    required String assetSymbol,
    required String assetClass,
    String? assetDisplayName,
    int replyCount = 0,
    int likeCount = 0,
    bool likedByMe = false,
    bool moderationHiddenFromPublic = false,
  }) {
    return CommunityPost(
      id: id,
      body: body,
      title: title,
      imageUrls: imageUrls,
      authorUid: authorUid,
      authorDisplayName: authorDisplayName,
      authorPhotoUrl: authorPhotoUrl,
      createdAt: createdAt,
      assetSymbol: assetSymbol,
      assetClass: assetClass,
      assetDisplayName: assetDisplayName,
      replyCount: replyCount,
      likeCount: likeCount,
      likedByMe: likedByMe,
      moderationHiddenFromPublic: moderationHiddenFromPublic,
    );
  }

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final rawName = json['author_display_name'] as String?;
    final name =
        rawName == null || rawName.trim().isEmpty ? 'User' : rawName.trim();
    final rawPhoto = json['author_photo_url'];
    final photoUrl = rawPhoto is String && rawPhoto.trim().isNotEmpty
        ? rawPhoto.trim()
        : null;
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
      authorPhotoUrl: photoUrl,
      createdAt: DateTime.parse(json['created_at'] as String),
      assetSymbol: json['asset_symbol'] as String,
      assetClass: json['asset_class'] as String,
      assetDisplayName: json['asset_display_name'] as String?,
      replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
      moderationHiddenFromPublic:
          json['moderation_hidden_from_public'] as bool? ?? false,
    );
  }
}

