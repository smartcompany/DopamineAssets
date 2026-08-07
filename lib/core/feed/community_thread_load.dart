// Pure helpers for community post-detail thread reloads.
// `_loadThread` can overlap (initial load + post/edit/delete reload). Callers
// bump a generation and only apply results when [isCurrentThreadLoad] is true.

bool isCurrentThreadLoad({required int gen, required int currentGen}) {
  return gen == currentGen;
}

/// Clears a reply-composer parent when that comment is no longer in the thread
/// (deleted, or not returned). Root id remains a valid parent.
String? reconcileReplyParentId({
  required String? replyParentId,
  required String rootId,
  required Set<String> threadIds,
}) {
  if (replyParentId == null) return null;
  if (replyParentId == rootId) return replyParentId;
  if (threadIds.contains(replyParentId)) return replyParentId;
  return null;
}
