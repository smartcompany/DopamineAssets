/// Walks `parentId` links until a root comment (no parent) is found.
///
/// Used when an entry point may pass a reply id (profile `my_reply` cards,
/// shared `/communityPost?postId=` links) but the detail screen must open the
/// true thread root — otherwise replies attach under the wrong parent and
/// root-only edit UI can mutate a reply as if it were a post.
Future<String> resolveThreadRootCommentId({
  required String commentId,
  required Future<String?> Function(String id) fetchParentId,
  int maxDepth = 50,
}) async {
  var cur = commentId.trim();
  if (cur.isEmpty) {
    throw ArgumentError.value(commentId, 'commentId', 'must be non-empty');
  }
  for (var i = 0; i < maxDepth; i++) {
    final parent = (await fetchParentId(cur))?.trim();
    if (parent == null || parent.isEmpty) return cur;
    cur = parent;
  }
  return cur;
}
