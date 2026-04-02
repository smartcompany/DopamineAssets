// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dopamine Assets';

  @override
  String get homeHeaderTitleDecorated => '🔥 Dopamine Assets 🔥';

  @override
  String get navHome => 'Home';

  @override
  String get actionLogin => 'Log in';

  @override
  String get navCommunity => 'Community';

  @override
  String get favoritesEmpty => 'No saved favorites yet.';

  @override
  String get favoritesSignInToSave =>
      'Sign in to save and view favorites on this device.';

  @override
  String get navProfile => 'Profile';

  @override
  String get profileSignedInSection => 'Account';

  @override
  String get profileAccountRefreshTooltip => 'Refresh profile and activity';

  @override
  String get profileDisplayName => 'Display name';

  @override
  String get profilePhotoTitle => 'Profile photo';

  @override
  String get profilePhotoRemove => 'Remove photo';

  @override
  String get profilePhotoSaved => 'Profile photo saved.';

  @override
  String get profilePhotoRemoved => 'Profile photo removed.';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileUid => 'User ID';

  @override
  String get profileNoEmail => 'Not set (social login)';

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileLogoutDone => 'Signed out.';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileDeleteTitle => 'Delete account?';

  @override
  String get profileDeleteMessage =>
      'This cannot be undone. Your Firebase account and sign-in will be removed.';

  @override
  String get profileDeleteCancel => 'Cancel';

  @override
  String get profileDeleteConfirm => 'Delete';

  @override
  String get profileDeleteDone => 'Account deleted.';

  @override
  String get profileRequiresRecentLogin =>
      'Please sign in again and retry (security).';

  @override
  String get profileNotSignedIn => 'Sign in to see your account.';

  @override
  String get profileSaveDisplayName => 'Save';

  @override
  String get profileDisplayNameHint => 'How your name appears on posts';

  @override
  String get profilePushTitle => 'Push notifications';

  @override
  String get profileSettingsTitle => 'Settings';

  @override
  String get profileSettingsMoreSoon => 'More settings coming soon.';

  @override
  String get profilePushMaster => 'All notifications';

  @override
  String get profilePushSocialReply => 'Replies to my posts/comments';

  @override
  String get profilePushSocialLike => 'Likes on my comments';

  @override
  String get profilePushMarketDaily => 'Daily market brief';

  @override
  String get profileStatPosts => 'Posts';

  @override
  String get profileStatFollowing => 'Following';

  @override
  String get profileStatFollowers => 'Followers';

  @override
  String get profileStatBlocked => 'Blocked';

  @override
  String get profileBlockedTitle => 'Blocked users';

  @override
  String get profileBlockedListEmpty => 'You have not blocked anyone.';

  @override
  String get profileUnblockAction => 'Unblock';

  @override
  String get profileUnblockedDone => 'Unblocked.';

  @override
  String get profileActivityTitle => 'Activity';

  @override
  String get profileActivityMyPost => 'Your post';

  @override
  String profileActivityPostOnAsset(String assetName) {
    return 'Post on $assetName';
  }

  @override
  String get profileActivityMyReply => 'Your reply';

  @override
  String get profileActivityReplyOnPost => 'Reply on your post';

  @override
  String get profileActivityLikeReceived => 'Like on your comment';

  @override
  String get profileActivityLikeGiven => 'You liked a comment';

  @override
  String get profileActivityEditPost => 'Edit';

  @override
  String get profileActivityDeletePost => 'Delete';

  @override
  String get profileActivityEditDialogTitle => 'Edit post';

  @override
  String get profileActivityDeleteDialogTitle => 'Delete this post?';

  @override
  String get profileActivityPostDeleted => 'Deleted.';

  @override
  String get profileActivityPostUpdated => 'Saved.';

  @override
  String get profileFollowListEmpty => 'No users yet.';

  @override
  String get profileDisplayNameSaved => 'Display name updated.';

  @override
  String get profileDisplayNameTaken => 'This display name is already taken.';

  @override
  String get profileDisplayNameDuplicateFromSocialTitle => 'Display name';

  @override
  String profileDisplayNameDuplicateFromSocialMessage(String name) {
    return 'The name from your sign-in provider, \"$name\", is already in use. Enter a different display name below and tap Save.';
  }

  @override
  String get profileDisplayNameDuplicateFromSocialOk => 'OK';

  @override
  String get privacyProcessingConsentTitle =>
      'Personal data processing consent';

  @override
  String get privacyProcessingConsentLead =>
      'Please review and accept the following to continue using the service.';

  @override
  String get privacyProcessingConsentBullet1 =>
      'Data collected: account identifier (Firebase UID), email if provided, display name and profile photo, and information generated through use such as posts, comments, and watchlists.';

  @override
  String get privacyProcessingConsentBullet2 =>
      'Purposes: identification, community and feed features, support, abuse prevention, and service improvement.';

  @override
  String get privacyProcessingConsentBullet3 =>
      'Retention: we delete or anonymize data when you delete your account, except where law requires longer retention.';

  @override
  String get privacyProcessingConsentCheckbox =>
      'I agree to the collection and use of my personal data as described above.';

  @override
  String get privacyProcessingConsentAgree => 'Agree and continue';

  @override
  String get privacyProcessingConsentDecline => 'Decline';

  @override
  String get profileFollowUnfollow => 'Unfollow';

  @override
  String get profileFollowTitleFollowing => 'Following';

  @override
  String get profileFollowTitleFollowers => 'Followers';

  @override
  String get communityFollow => 'Follow';

  @override
  String get communityUnfollow => 'Unfollow';

  @override
  String get communityOpenAssetDetail => 'Asset details';

  @override
  String get communityMoreMenu => 'More';

  @override
  String get communityPostSeeMore => 'See more >';

  @override
  String get communityReportPost => 'Report';

  @override
  String get communityBlockAuthor => 'Block user';

  @override
  String get communityPostHiddenByReportNotice =>
      'This post is hidden from other users after a report review.';

  @override
  String get communityBlockAuthorHint =>
      'Blocking unfollows this user and hides their posts from you.';

  @override
  String get communityBlockAuthorMenuSubtitle => 'User';

  @override
  String get communityReportPostMenuSubtitle => 'This post';

  @override
  String get communityBlockAuthorShort => 'Block';

  @override
  String get communityReportPostShort => 'Report';

  @override
  String get communityReportDialogTitle => 'Report this post?';

  @override
  String get communityReportReasonHint => 'Reason (optional)';

  @override
  String get communityReportSend => 'Report';

  @override
  String get communityReportSheetTitle => 'Report';

  @override
  String get communityReportSheetSubtitle => 'Select a reason for your report.';

  @override
  String get communityReportReasonSpam => 'Spam or ads';

  @override
  String get communityReportReasonAbuse => 'Harassment or hate';

  @override
  String get communityReportReasonSexual => 'Sexual content';

  @override
  String get communityReportReasonViolence => 'Violence or threats';

  @override
  String get communityReportReasonOther => 'Other';

  @override
  String get communityReportDetailHint => 'Add details (optional)';

  @override
  String get communityReportSubmitButton => 'Submit report';

  @override
  String get communityReportSubmitted => 'Thanks — your report was submitted.';

  @override
  String get communityBlockAuthorTitle => 'Block this user?';

  @override
  String communityBlockAuthorMessage(String authorName) {
    return 'You will no longer see posts or this profile from $authorName.';
  }

  @override
  String get communityUserBlocked => 'User blocked.';

  @override
  String get communityLikeLogin => 'Sign in to like.';

  @override
  String communityLikeCount(int count) {
    return '$count';
  }

  @override
  String communityCommentCount(int count) {
    return '$count';
  }

  @override
  String get communityPostDetailTitle => 'Post';

  @override
  String get communityCommentsTitle => 'Comments';

  @override
  String get communityWrite => 'Write';

  @override
  String get communityComposeTitle => 'New post';

  @override
  String get communityComposeSubmit => 'Post';

  @override
  String get communityComposeOptionalTitle => 'Title (optional)';

  @override
  String get communityComposeTitleHint => 'Add a title or leave blank';

  @override
  String get communityComposeSymbolLabel => 'Symbol';

  @override
  String get communityComposeThemePickerLabel => 'Theme';

  @override
  String get communityComposePickTheme => 'Choose a theme';

  @override
  String get communityComposeSymbolHint => 'e.g. TSLA, IBRX';

  @override
  String get communityComposeAssetClassLabel => 'Asset type';

  @override
  String get communityComposeBodyLabel => 'Body';

  @override
  String get communityComposeBodyHint =>
      'Spam, ads, harassment, or abuse may be removed; repeated violations may restrict your account. Please keep discussion respectful.';

  @override
  String get communityComposePhotosLabel => 'Photos';

  @override
  String get communityComposeNeedSymbol => 'Choose a symbol.';

  @override
  String get communityComposeNeedBody => 'Enter the body text.';

  @override
  String get communityComposePickSymbol => 'Choose symbol';

  @override
  String get communityComposeNoRankedSymbols =>
      'No ranked symbols for this asset type. Open Home to load rankings and try again.';

  @override
  String get communityComposeAddPhotoShort => 'Photo';

  @override
  String get communityComposeEditTitle => 'Edit post';

  @override
  String get communityComposeSave => 'Save';

  @override
  String get communityComposeEditReplyTitle => 'Edit reply';

  @override
  String ugcBannedWordsMessage(String term) {
    return 'This text contains disallowed wording: $term';
  }

  @override
  String get navRankings => 'Rankings';

  @override
  String get navThemes => 'Themes';

  @override
  String get navMarket => 'Market';

  @override
  String get homeRankingApplyFiltersTooltip =>
      'Apply selected filters to rankings';

  @override
  String get rankingsUpTab => 'Surging 🔥';

  @override
  String get rankingsDownTab => 'Crashing 💀';

  @override
  String get rankingsUpTitle => 'Wildest gainers today';

  @override
  String get rankingsDownTitle => 'Biggest losers today';

  @override
  String get themesHotTitle => 'Hottest themes today';

  @override
  String get themesCrashedTitle => 'Themes that got crushed';

  @override
  String get themesEmergingTitle => 'Suddenly trending themes';

  @override
  String get marketSummaryTitle => 'Market summary';

  @override
  String get kimchiPremiumLabel => 'Kimchi premium';

  @override
  String get exchangeRateLabel => 'Exchange rate';

  @override
  String get marketStatusLabel => 'Market mood';

  @override
  String get dopamineScoreLabel => 'Dopamine score';

  @override
  String get errorLoadFailed => 'Could not load data.';

  @override
  String get errorNoApi =>
      'API base URL is not set. Pass --dart-define=API_BASE_URL=... when running.';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading…';

  @override
  String get emptyState => 'No data to show.';

  @override
  String get assetName => 'Asset';

  @override
  String get priceChangePct => 'Price change';

  @override
  String get volumeChangePct => 'Volume change';

  @override
  String get summaryLine => 'Summary';

  @override
  String get themeName => 'Theme';

  @override
  String get themeScore => 'Theme score';

  @override
  String get stockCount => 'Symbols';

  @override
  String get sectionRankings => 'Up · Down';

  @override
  String get sectionThemes => 'Theme rankings';

  @override
  String get sectionMarket => 'Market summary';

  @override
  String get notAvailable => 'N/A';

  @override
  String get homeTopSurgeBadge => 'TOP 10';

  @override
  String get homeKicker => 'Only what moves. Where money flows right now.';

  @override
  String get homeLiveBadge => 'LIVE';

  @override
  String homeThemeStockLine(int count) {
    return '$count stocks';
  }

  @override
  String get assetClassBadgeUsStock => 'US stock';

  @override
  String get assetClassBadgeKrStock => 'Korea';

  @override
  String get assetClassBadgeCrypto => 'Crypto';

  @override
  String get assetClassBadgeCommodity => 'Commodity';

  @override
  String get assetClassBadgeTheme => 'Theme';

  @override
  String get communityComposeThemeNameHint =>
      'Theme name (e.g. Energy & commodities)';

  @override
  String get rankingFilterTitle => 'Asset classes';

  @override
  String get rankingFilterConfirm => 'OK';

  @override
  String get rankingFilterCancel => 'Cancel';

  @override
  String get rankingFilterNeedOne => 'Select at least one.';

  @override
  String get assetDetailMissingClass => 'Missing asset class for this item.';

  @override
  String get assetDetailSectionProfile => 'Profile';

  @override
  String get assetDetailMarketCap => 'Market cap';

  @override
  String assetDetailMarketCapKrwMillions(String amount) {
    return '${amount}M KRW';
  }

  @override
  String assetDetailMarketCapKrwWonFull(String amount) {
    return '$amount KRW';
  }

  @override
  String get assetDetailMarketCapRank => 'Market cap rank';

  @override
  String get assetDetailCurrentPrice => 'Price (USD)';

  @override
  String get assetDetailCryptoProfileMore => 'More';

  @override
  String get assetDetailCryptoProfileLess => 'Less';

  @override
  String get assetDetailSector => 'Sector';

  @override
  String get assetDetailIndustry => 'Industry';

  @override
  String get assetDetailExchange => 'Exchange';

  @override
  String get assetDetailCurrency => 'Currency';

  @override
  String get assetDetailPair => 'Pair';

  @override
  String get assetDetailAbout => 'About';

  @override
  String get assetDetailWebsite => 'Website';

  @override
  String get assetDetailNotAvailable => '—';

  @override
  String get assetDetailOpenLinkFailed => 'Could not open link.';

  @override
  String get assetDetailPriceChange => 'Price change (feed)';

  @override
  String get communitySortLatest => 'Latest';

  @override
  String get communitySortPopular => 'Popular';

  @override
  String communityReplyCount(int count) {
    return 'Replies: $count';
  }

  @override
  String get assetPostsTitle => 'Recent reactions';

  @override
  String get assetPostsEmpty => 'Be the first to post.';

  @override
  String get assetPostsPlaceholder => 'Leave a comment.';

  @override
  String get assetPostsReplyPlaceholder => 'Write a reply.';

  @override
  String get assetPostsPublish => 'Post';

  @override
  String get assetPostsReply => 'Reply';

  @override
  String get assetPostsReplying => 'Replying';

  @override
  String get assetPostsCancelReply => 'Cancel';

  @override
  String get assetPostsSendError => 'Could not publish your post.';

  @override
  String get assetDetailMoveSummary => 'Today’s move (AI)';

  @override
  String get assetDetailMoveSummaryDisclaimer =>
      'AI-generated from public figures only—not investment advice.';

  @override
  String get assetDetailNewsTitle => 'Headlines';

  @override
  String get assetDetailNewsEmpty => 'No recent headlines for this search.';

  @override
  String get assetDetailNewsError =>
      'Could not load headlines. Check your connection or try again.';

  @override
  String get assetDetailNewsDisclaimer =>
      'Headlines from third-party sources—titles and links only.';

  @override
  String get assetDetailNewsShowMore => 'Show more';

  @override
  String get assetDetailNewsShowLess => 'Show less';

  @override
  String get assetDetailNewsWatchAdAiAnalysis => 'Watch ad · AI news analysis';

  @override
  String get assetDetailOpenCommunity => 'Community';

  @override
  String get communitySearchHint => 'Search words in posts (OR)…';

  @override
  String get assetDetailOpenChart => 'View chart';

  @override
  String get assetChartRange1mo => '1M';

  @override
  String get assetChartRange3mo => '3M';

  @override
  String get assetChartRange1y => '1Y';

  @override
  String get assetChartFootnote =>
      'Daily candles via Yahoo (server). Not investment advice.';

  @override
  String get themeDetailChartTitle => 'Theme average (normalized)';

  @override
  String get themeDetailChartFootnote =>
      'Synthetic index: each symbol rebased to 100 at its first bar in the range, then averaged by calendar day. Yahoo daily via server. Not investment advice.';
}
