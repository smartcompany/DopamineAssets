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
}

