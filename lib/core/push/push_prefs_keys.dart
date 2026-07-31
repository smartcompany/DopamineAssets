/// Canonical keys for user push notification preferences.
/// Keep in sync with server BOOL_KEYS / DB_MAP in
/// `server/src/app/api/profile/push-prefs/route.ts`.
abstract final class PushPrefsKeys {
  PushPrefsKeys._();

  // Snake_case: how the rest of the client stores them internally.
  static const masterEnabled = 'master_enabled';
  static const socialReply = 'social_reply';
  static const socialLike = 'social_like';
  static const followedNewPost = 'followed_new_post';
  static const moderationNotice = 'moderation_notice';
  static const marketDailyBrief = 'market_daily_brief';
  static const marketWatchlist = 'market_watchlist';
  static const marketTheme = 'market_theme';
  static const hotMoverDiscussion = 'hot_mover_discussion';

  /// Client snake_case → API camelCase. Only keys present in [clientPatch]
  /// are included so callers can send single-key PATCHes safely.
  static Map<String, dynamic> toApiBody(Map<String, dynamic> clientPatch) {
    const mapping = <String, String>{
      masterEnabled: 'masterEnabled',
      socialReply: 'socialReply',
      socialLike: 'socialLike',
      followedNewPost: 'followedNewPost',
      moderationNotice: 'moderationNotice',
      marketDailyBrief: 'marketDailyBrief',
      marketWatchlist: 'marketWatchlist',
      marketTheme: 'marketTheme',
      hotMoverDiscussion: 'hotMoverDiscussion',
    };
    final body = <String, dynamic>{};
    for (final entry in mapping.entries) {
      if (clientPatch.containsKey(entry.key)) {
        body[entry.value] = clientPatch[entry.key];
      }
    }
    return body;
  }

  /// Whether a profile load's fetched prefs should overwrite local state.
  ///
  /// Rejects results captured before a newer mutation ([loadEpoch] stale) and
  /// any result that arrives while a mutation is still in flight (GET may have
  /// started after the toggle began but before the PATCH committed).
  static bool shouldApplyFetchedPrefs({
    required int loadEpoch,
    required int currentEpoch,
    required bool mutationInFlight,
  }) {
    if (mutationInFlight) return false;
    return loadEpoch == currentEpoch;
  }
}

