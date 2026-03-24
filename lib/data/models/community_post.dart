final class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.body,
    required this.authorUid,
    required this.authorDisplayName,
    required this.createdAt,
    required this.assetSymbol,
    required this.assetClass,
    required this.replyCount,
  });

  final String id;
  final String body;
  final String authorUid;
  final String authorDisplayName;
  final DateTime createdAt;
  final String assetSymbol;
  final String assetClass;
  final int replyCount;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final rawName = json['author_display_name'] as String?;
    final name =
        rawName == null || rawName.trim().isEmpty ? 'User' : rawName.trim();
    return CommunityPost(
      id: json['id'] as String,
      body: json['body'] as String,
      authorUid: json['author_uid'] as String,
      authorDisplayName: name,
      createdAt: DateTime.parse(json['created_at'] as String),
      assetSymbol: json['asset_symbol'] as String,
      assetClass: json['asset_class'] as String,
      replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
    );
  }
}
