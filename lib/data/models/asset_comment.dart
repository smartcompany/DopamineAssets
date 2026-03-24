final class AssetComment {
  const AssetComment({
    required this.id,
    this.parentId,
    required this.body,
    required this.authorUid,
    required this.authorDisplayName,
    required this.createdAt,
  });

  final String id;
  final String? parentId;
  final String body;
  final String authorUid;
  final String authorDisplayName;
  final DateTime createdAt;

  factory AssetComment.fromJson(Map<String, dynamic> json) {
    final rawName = json['author_display_name'] as String?;
    final name = rawName == null || rawName.trim().isEmpty ? 'User' : rawName.trim();
    return AssetComment(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      body: json['body'] as String,
      authorUid: json['author_uid'] as String,
      authorDisplayName: name,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
