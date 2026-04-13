// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '多巴胺资产';

  @override
  String get homeHeaderTitleDecorated => '多巴胺资产';

  @override
  String get navHome => '主页';

  @override
  String get actionLogin => '登录';

  @override
  String get navCommunity => '社区';

  @override
  String get favoritesEmpty => '尚未保存收藏。';

  @override
  String get favoritesSignInToSave => '登录以在此设备上保存和查看收藏夹。';

  @override
  String get navProfile => '個人檔案';

  @override
  String get profileSignedInSection => '账户';

  @override
  String get profileAccountRefreshTooltip => '刷新个人资料和活动';

  @override
  String get profileDisplayName => '显示名称';

  @override
  String get profilePhotoTitle => '头像照片';

  @override
  String get profilePhotoRemove => '移除照片';

  @override
  String get profilePhotoSaved => '个人头像已保存。';

  @override
  String get profilePhotoRemoved => '个人头像已删除。';

  @override
  String get profileEmail => '电子邮箱';

  @override
  String get profileUid => '用户ID';

  @override
  String get profileNoEmail => '未设置（社交登录）';

  @override
  String get profileLogout => '注销登录';

  @override
  String get profileLogoutDone => '已注销。';

  @override
  String get profileDeleteAccount => '删除账户';

  @override
  String get profileDeleteTitle => '删除账户';

  @override
  String get profileDeleteMessage => '此操作无法撤消。您的Firebase帐户和登录将被删除。';

  @override
  String get profileDeleteCancel => '取消';

  @override
  String get profileDeleteConfirm => '删除';

  @override
  String get profileDeleteDone => '帐户已被删除。';

  @override
  String get profileRequiresRecentLogin => '请重新登录并重试（安全）。';

  @override
  String get profileNotSignedIn => '登录到你的账户。';

  @override
  String get profileSaveDisplayName => '确认保存';

  @override
  String get profileDisplayNameHint => '您的姓名在帖子中的显示方式';

  @override
  String get profileDisplayNameInputPlaceholder => '输入显示名';

  @override
  String get profileCheckDisplayNameDuplicate => '查看余票情况';

  @override
  String get profileDisplayNameEmpty => '請輸入顯示名稱。';

  @override
  String get profileDisplayNameCheckFirst => '保存前，请检查可订状态。';

  @override
  String get profileNicknameRequiredForCommunity => '在个人资料中设置您的显示名称。';

  @override
  String get profilePushTitle => '推送通知';

  @override
  String get profileSettingsTitle => '设置';

  @override
  String get profileSettingsLegalDisclosures => '数据源和免责声明';

  @override
  String get profilePushMaster => '所有通知';

  @override
  String get profilePushSocialReply => '回复我的帖子/评论';

  @override
  String get profilePushSocialLike => '对我的评论点赞';

  @override
  String get profilePushMarketDaily => '每日市场汇总';

  @override
  String get profilePushHotMoverDiscussion => '热门话题--热烈讨论';

  @override
  String get profileStatPosts => '文章';

  @override
  String get profileStatFollowing => '追蹤';

  @override
  String get profileStatFollowers => '粉丝';

  @override
  String get profileStatBlocked => '封锁';

  @override
  String get profileBlockedTitle => '阻止的用户';

  @override
  String get profileBlockedListEmpty => '您没有屏蔽任何人。';

  @override
  String get profileUnblockAction => '取消屏蔽';

  @override
  String get profileUnblockedDone => '解除阻止';

  @override
  String get profileActivityTitle => '活跃度';

  @override
  String get profileActivityMyPost => '你的文章';

  @override
  String profileActivityPostOnAsset(String assetName) {
    return '发布于$assetName';
  }

  @override
  String get profileActivityMyReply => '你的回复';

  @override
  String get profileActivityReplyOnPost => '在帖子上回复';

  @override
  String get profileActivityLikeReceived => '对您的评论点赞';

  @override
  String get profileActivityLikeGiven => '您点赞了一条评论';

  @override
  String get profileActivityEditPost => '修改';

  @override
  String get profileActivityDeletePost => '删除';

  @override
  String get profileActivityEditDialogTitle => '排除帖子';

  @override
  String get profileActivityDeleteDialogTitle => '删除此帖子';

  @override
  String get profileActivityPostDeleted => '已删除。';

  @override
  String get profileActivityPostUpdated => '已保存.';

  @override
  String get profileFollowListEmpty => '尚无用户';

  @override
  String get profileDisplayNameSaved => '显示名称已更新。';

  @override
  String get profileDisplayNameTaken => '此名称已被使用';

  @override
  String get profileDisplayNameDuplicateFromSocialTitle => '显示名称';

  @override
  String profileDisplayNameDuplicateFromSocialMessage(String name) {
    return '登录提供商的姓名「$name」已被使用。在下方输入新名称，轻点查看可订状态，然后轻点保存。';
  }

  @override
  String get profileDisplayNameDuplicateFromSocialOk => '确认';

  @override
  String get privacyProcessingConsentTitle => '条款、社区和隐私';

  @override
  String get privacyProcessingConsentLead =>
      '要使用服务（包括社区和其他用户生成的内容） ，请先阅读并接受以下内容，然后再继续。';

  @override
  String get privacyProcessingConsentSectionPrivacy => '个人数据';

  @override
  String get privacyProcessingConsentSectionCommunity => '社区和用户生成内容（ UGC ）';

  @override
  String get privacyProcessingConsentUgcIntro => '在您访问帖子、评论和其他UGC之前，请遵循以下规则：';

  @override
  String get privacyProcessingConsentBullet1 =>
      '收集的数据：帐户标识符（ Firebase UID ）、电子邮件（如提供）、显示名称和个人资料照片，以及通过使用而生成的信息，如帖子、评论和监视列表。';

  @override
  String get privacyProcessingConsentBullet2 => '目的：识别、社区和Feed功能、支持、滥用预防和服务改进。';

  @override
  String get privacyProcessingConsentBullet3 =>
      '保留：我们会在您删除账号时删除或匿名处理数据，除非法律要求更长时间的保留。';

  @override
  String get privacyProcessingConsentUgcBullet1 =>
      '零容忍：不允许出现令人反感的内容。这包括非法材料、骚扰、仇恨、未经同意的性内容、暴力、威胁、垃圾邮件、诈骗和类似的虐待。';

  @override
  String get privacyProcessingConsentUgcBullet2 =>
      '我们绝不容忍侮辱性用户。我们可能会删除内容、限制功能、暂停或终止违反这些规则的账号。';

  @override
  String get privacyProcessingConsentUgcBullet3 =>
      '您可以在帖子菜单和个人资料中报告令人反感的帖子并屏蔽用户。如果您发现有害内容或行为，请使用举报功能并屏蔽。';

  @override
  String get privacyProcessingConsentCheckboxPrivacy =>
      '我同意按照上述个人数据部分所述收集和使用我的个人数据。';

  @override
  String get privacyProcessingConsentCheckboxCommunity =>
      '我同意上述社区和UGC规则，包括对令人反感的内容和虐待用户的零容忍。';

  @override
  String get privacyProcessingConsentAgree => '同意并继续';

  @override
  String get privacyProcessingConsentDecline => '拒绝';

  @override
  String get profileFollowUnfollow => '未关注';

  @override
  String get profileFollowTitleFollowing => '追蹤';

  @override
  String get profileFollowTitleFollowers => '粉丝';

  @override
  String get communityFollow => '跟随';

  @override
  String get communityUnfollow => '未关注';

  @override
  String get communityOpenAssetDetail => '资产明细';

  @override
  String get communityMoreMenu => '更多';

  @override
  String get communityPostSeeMore => '顯示更多';

  @override
  String get communityShowOriginal => '查看原文';

  @override
  String get communityShowTranslated => '查看翻译';

  @override
  String get communityReportPost => '报告';

  @override
  String get communityBlockAuthor => '拉入黑名单';

  @override
  String get communityPostHiddenByReportNotice => '报告审核后，此帖子对其他用户隐藏。';

  @override
  String get communityBlockAuthorHint => '屏蔽会取消关注此用户，并向您隐藏其帖子。';

  @override
  String get communityBlockAuthorMenuSubtitle => '用户';

  @override
  String get communityReportPostMenuSubtitle => '这个帖子';

  @override
  String get communityBlockAuthorShort => '格挡';

  @override
  String get communityReportPostShort => '报告';

  @override
  String get communityReportDialogTitle => '举报此帖子';

  @override
  String get communityReportReasonHint => '原因（可选）';

  @override
  String get communityReportSend => '报告';

  @override
  String get communityReportSheetTitle => '报告';

  @override
  String get communityReportSheetSubtitle => '选择您的举报原因';

  @override
  String get communityReportReasonSpam => '垃圾邮件或广告';

  @override
  String get communityReportReasonAbuse => '「骚扰」或';

  @override
  String get communityReportReasonSexual => '色情内容';

  @override
  String get communityReportReasonViolence => '暴力或威胁';

  @override
  String get communityReportReasonOther => 'Other';

  @override
  String get communityReportDetailHint => '詳情（選擇）';

  @override
  String get communityReportSubmitButton => '提交报告';

  @override
  String get communityReportSubmitted => '谢谢！您的举报已提交。';

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
  String get communityComposeAddGifShort => 'GIF';

  @override
  String get communityComposeGiphySearchHint => 'Search GIPHY';

  @override
  String get communityComposeGiphyPoweredBy => 'Powered by GIPHY';

  @override
  String get communityComposeGiphyTooLarge =>
      'This file is over 5MB. Pick another GIF.';

  @override
  String get communityComposeGiphyDownloadError =>
      'Could not load the GIF. Try again.';

  @override
  String get communityComposeGiphyRateLimited =>
      'Please try again in a moment. (rate limit)';

  @override
  String get communityComposeGiphyLoadError => 'Could not load the list.';

  @override
  String get communityComposeGiphyRetry => 'Retry';

  @override
  String get communityComposeGiphyEmpty => 'No results.';

  @override
  String get communityComposeGiphyThumbError => 'Preview unavailable';

  @override
  String get communityComposeEditTitle => '排除帖子';

  @override
  String get communityComposeSave => '确认保存';

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
  String get homeRankingsShareTooltip => 'Share rankings';

  @override
  String get homeRankingsShareEmptySnack => 'No rankings to share yet.';

  @override
  String homeRankingsShareFiltersLine(String filters) {
    return 'Filters: $filters';
  }

  @override
  String get homeInterestSurgeTitle => 'Today\'s interest surge';

  @override
  String get homeInterestSurgeInfoIconTooltip => 'How this list is built';

  @override
  String get homeInterestSurgeInfoTitle => 'About today\'s interest surge';

  @override
  String get homeInterestSurgeInfoBody =>
      'This list is built with AI: it picks US and Korean stocks, crypto, and commodities that look attention-worthy from recent market context, news, and investor-interest signals, then estimates a relative 0–100 \"trend\" score for each.\n\nScores are processed and stored on our servers once per day; the app shows the latest snapshot.\n\nFor information only—not investment advice, and not a guarantee of returns.';

  @override
  String get homeInterestSurgeInfoDismiss => '确认';

  @override
  String get homeTrendScoreLabel => 'Trend';

  @override
  String get homeRankingShowMoreTooltip => 'Show more';

  @override
  String get homeInterestSurgeShowMoreWithAd => 'Watch ad to show more';

  @override
  String get homeRankingShowLessTooltip => 'Show less';

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
  String get assetClassBadgeJpStock => 'Japan';

  @override
  String get assetClassBadgeCnStock => 'China';

  @override
  String get assetClassJpStock => 'Japan stocks';

  @override
  String get assetClassCnStock => 'China A-shares';

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
  String get rankingFilterConfirm => '确认';

  @override
  String get rankingFilterCancel => '取消';

  @override
  String get rankingFilterNeedOne => 'Select at least one.';

  @override
  String get assetDetailMissingClass => 'Missing asset class for this item.';

  @override
  String get assetDetailSectionProfile => '個人檔案';

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
  String get assetDetailCryptoProfileMore => '更多';

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
  String get assetPostsCancelReply => '取消';

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
  String get assetDetailOpenCommunity => '社区';

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

  @override
  String get accountSuspendedBanner =>
      'Your account cannot post, edit, delete, or reply in the community right now.';

  @override
  String get accountSuspendedSnack =>
      'This account is restricted from community activity.';

  @override
  String get shareSheetKakaoTalk => '分享到 KakaoTalk';

  @override
  String get shareSheetSystemShare => '系统分享';

  @override
  String get shareSheetCopyLink => '复制链接';

  @override
  String get shareSheetCopied => '已复制';
}
