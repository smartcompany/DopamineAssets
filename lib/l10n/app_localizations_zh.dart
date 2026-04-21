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
  String get navFavorites => '自选';

  @override
  String get favoritesEmpty => '尚未保存收藏。';

  @override
  String get favoritesSignInToSave => '登录以在此设备上保存和查看收藏夹。';

  @override
  String get navProfile => '个人资料';

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
  String get profileCheckDisplayNameDuplicate => '检查名称是否可用';

  @override
  String get profileDisplayNameEmpty => '请输入显示名称。';

  @override
  String get profileDisplayNameCheckFirst => '保存前请先检查名称是否可用。';

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
  String get profileStatFollowing => '关注';

  @override
  String get profileStatFollowers => '粉丝';

  @override
  String get profileStatBlocked => '已屏蔽';

  @override
  String get profileBlockedTitle => '已屏蔽用户';

  @override
  String get profileBlockedListEmpty => '您没有屏蔽任何人。';

  @override
  String get profileUnblockAction => '取消屏蔽';

  @override
  String get profileUnblockedDone => '已解除屏蔽';

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
  String get profileActivityEditDialogTitle => '编辑帖子';

  @override
  String get profileActivityDeleteDialogTitle => '删除此帖子';

  @override
  String get profileActivityPostDeleted => '已删除。';

  @override
  String get profileActivityPostUpdated => '已保存。';

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
    return '登录提供商的姓名「$name」已被占用。请在下方输入新名称，先检查是否可用，再保存。';
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
  String get profileFollowTitleFollowing => '关注';

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
  String get communityPostSeeMore => '显示更多';

  @override
  String get communityShowOriginal => '查看原文';

  @override
  String get communityShowTranslated => '查看翻译';

  @override
  String get communityReportPost => '举报';

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
  String get communityBlockAuthorShort => '屏蔽';

  @override
  String get communityReportPostShort => '举报';

  @override
  String get communityReportDialogTitle => '举报此帖子';

  @override
  String get communityReportReasonHint => '原因（可选）';

  @override
  String get communityReportSend => '提交举报';

  @override
  String get communityReportSheetTitle => '举报';

  @override
  String get communityReportSheetSubtitle => '选择您的举报原因';

  @override
  String get communityReportReasonSpam => '垃圾邮件或广告';

  @override
  String get communityReportReasonAbuse => '骚扰或仇恨';

  @override
  String get communityReportReasonSexual => '色情内容';

  @override
  String get communityReportReasonViolence => '暴力或威胁';

  @override
  String get communityReportReasonOther => '其他';

  @override
  String get communityReportDetailHint => '详情（可选）';

  @override
  String get communityReportSubmitButton => '提交报告';

  @override
  String get communityReportSubmitted => '谢谢！您的举报已提交。';

  @override
  String get communityBlockAuthorTitle => '屏蔽此用户？';

  @override
  String communityBlockAuthorMessage(String authorName) {
    return '屏蔽后，您将不再看到来自 $authorName 的帖子或其个人主页。';
  }

  @override
  String get communityUserBlocked => '已屏蔽该用户。';

  @override
  String get communityLikeLogin => '登录后即可点赞。';

  @override
  String communityLikeCount(int count) {
    return '$count';
  }

  @override
  String communityCommentCount(int count) {
    return '$count';
  }

  @override
  String get communityPostDetailTitle => '帖子';

  @override
  String get communityCommentsTitle => '评论';

  @override
  String get communityWrite => '写评论';

  @override
  String get communityComposeTitle => '发布新帖';

  @override
  String get communityComposeSubmit => '发布';

  @override
  String get communityComposeOptionalTitle => '标题（可选）';

  @override
  String get communityComposeTitleHint => '填写标题或留空';

  @override
  String get communityComposeSymbolLabel => '代码';

  @override
  String get communityComposeThemePickerLabel => '主题';

  @override
  String get communityComposePickTheme => '选择主题';

  @override
  String get communityComposeSymbolHint => '例如 TSLA、IBRX';

  @override
  String get communityComposeAssetClassLabel => '资产类型';

  @override
  String get communityComposeBodyLabel => '正文';

  @override
  String get communityComposeBodyHint =>
      '垃圾信息、广告、骚扰或辱骂内容可能被删除；屡次违规可能导致账号受限。请文明讨论。';

  @override
  String get communityComposePhotosLabel => '图片';

  @override
  String get communityComposeNeedSymbol => '请选择代码。';

  @override
  String get communityComposeNeedBody => '请输入正文。';

  @override
  String get communityComposePickSymbol => '选择代码';

  @override
  String get communityComposeNoRankedSymbols => '该资产类型暂无排行代码。请打开首页加载排行后再试。';

  @override
  String get communityComposeAddPhotoShort => '照片';

  @override
  String get communityComposeAddGifShort => '动图';

  @override
  String get communityComposeGiphySearchHint => '搜索 GIPHY';

  @override
  String get communityComposeGiphyPoweredBy => '由 GIPHY 提供支持';

  @override
  String get communityComposeGiphyTooLarge => '文件超过 5MB，请另选一张 GIF。';

  @override
  String get communityComposeGiphyDownloadError => '无法加载该 GIF，请重试。';

  @override
  String get communityComposeGiphyRateLimited => '请求过于频繁，请稍后再试。';

  @override
  String get communityComposeGiphyLoadError => '无法加载列表。';

  @override
  String get communityComposeGiphyRetry => '重试';

  @override
  String get communityComposeGiphyEmpty => '暂无结果。';

  @override
  String get communityComposeGiphyThumbError => '预览不可用';

  @override
  String get communityComposeEditTitle => '编辑帖子';

  @override
  String get communityComposeSave => '确认保存';

  @override
  String get communityComposeEditReplyTitle => '编辑回复';

  @override
  String ugcBannedWordsMessage(String term) {
    return '文本包含不允许的用语：$term';
  }

  @override
  String get navRankings => '排行榜';

  @override
  String get navThemes => '主题';

  @override
  String get navMarket => '市场';

  @override
  String get homeRankingApplyFiltersTooltip => '将所选资产类别应用到排行榜';

  @override
  String get rankingsUpTab => '暴涨 🔥';

  @override
  String get rankingsDownTab => '暴跌 💀';

  @override
  String get rankingsUpTitle => '今日最猛涨幅';

  @override
  String get rankingsDownTitle => '今日最大跌幅';

  @override
  String get homeRankingsShareTooltip => '分享排行榜';

  @override
  String get homeRankingsShareEmptySnack => '暂无可分享的排行数据。';

  @override
  String homeRankingsShareFiltersLine(String filters) {
    return '筛选：$filters';
  }

  @override
  String get homeInterestSurgeTitle => '今日关注飙升';

  @override
  String get homeInterestSurgeInfoIconTooltip => '此列表如何生成';

  @override
  String get homeInterestSurgeInfoTitle => '关于今日关注飙升';

  @override
  String get homeInterestSurgeInfoBody =>
      '该列表由 AI 生成：结合近期市场环境、新闻与投资者关注度信号，从美股、韩股、加密货币与大宗商品中筛选值得关注的标的，并为每个标的估算 0–100 的相对「热度」分数。\n\n分数每天在我们的服务器上处理并存储一次；应用展示最新快照。\n\n仅供参考，不构成投资建议，也不保证收益。';

  @override
  String get homeInterestSurgeInfoDismiss => '确定';

  @override
  String get homeTrendScoreLabel => '热度';

  @override
  String get homeRankingShowMoreTooltip => '展开更多';

  @override
  String get homeInterestSurgeShowMoreWithAd => '观看广告以显示更多';

  @override
  String get homeRankingShowLessTooltip => '收起';

  @override
  String get themesHotTitle => '今日最热主题';

  @override
  String get themesCrashedTitle => '今日重挫主题';

  @override
  String get themesEmergingTitle => '突然走红主题';

  @override
  String get marketSummaryTitle => '市场摘要';

  @override
  String get kimchiPremiumLabel => '泡菜溢价';

  @override
  String get exchangeRateLabel => '汇率';

  @override
  String get marketStatusLabel => '市场情绪';

  @override
  String get dopamineScoreLabel => '多巴胺指数';

  @override
  String get errorLoadFailed => '无法加载数据。';

  @override
  String get errorNoApi => '未设置 API 地址。运行请传入 --dart-define=API_BASE_URL=...';

  @override
  String get retry => '重试';

  @override
  String get loading => '加载中…';

  @override
  String get emptyState => '暂无数据。';

  @override
  String get assetName => '资产';

  @override
  String get priceChangePct => '涨跌幅';

  @override
  String get volumeChangePct => '成交量变化';

  @override
  String get summaryLine => '摘要';

  @override
  String get themeName => '主题';

  @override
  String get themeScore => '主题得分';

  @override
  String get stockCount => '标的数';

  @override
  String get sectionRankings => '涨跌榜';

  @override
  String get sectionThemes => '主题排行';

  @override
  String get sectionMarket => '市场摘要';

  @override
  String get notAvailable => '无';

  @override
  String get homeTopSurgeBadge => 'TOP 10';

  @override
  String get homeKicker => '只看波动，追随资金流向。';

  @override
  String get homeLiveBadge => '实时';

  @override
  String homeThemeStockLine(int count) {
    return '$count 只股票';
  }

  @override
  String get assetClassBadgeUsStock => '美股';

  @override
  String get assetClassBadgeKrStock => '韩股';

  @override
  String get assetClassBadgeJpStock => '日股';

  @override
  String get assetClassBadgeCnStock => '中股';

  @override
  String get assetClassJpStock => '日本股市';

  @override
  String get assetClassCnStock => '中国A股';

  @override
  String get assetClassBadgeCrypto => '加密货币';

  @override
  String get assetClassBadgeCommodity => '大宗商品';

  @override
  String get assetClassBadgeTheme => '主题';

  @override
  String get communityComposeThemeNameHint => '主题名称（例如：能源与大宗商品）';

  @override
  String get rankingFilterTitle => '资产类别';

  @override
  String get rankingFilterConfirm => '确认';

  @override
  String get rankingFilterCancel => '取消';

  @override
  String get rankingFilterNeedOne => '请至少选择一项。';

  @override
  String get assetDetailMissingClass => '缺少该标的的资产类别。';

  @override
  String get assetDetailSectionProfile => '概况';

  @override
  String get assetDetailMarketCap => '市值';

  @override
  String assetDetailMarketCapKrwMillions(String amount) {
    return '${amount}M KRW';
  }

  @override
  String assetDetailMarketCapKrwWonFull(String amount) {
    return '$amount KRW';
  }

  @override
  String get assetDetailMarketCapRank => '市值排名';

  @override
  String get assetDetailCurrentPrice => '价格（美元）';

  @override
  String get assetDetailCryptoProfileMore => '更多';

  @override
  String get assetDetailCryptoProfileLess => '收起';

  @override
  String get assetDetailSector => '行业板块';

  @override
  String get assetDetailIndustry => '细分行业';

  @override
  String get assetDetailExchange => '交易所';

  @override
  String get assetDetailCurrency => '计价货币';

  @override
  String get assetDetailPair => '交易对';

  @override
  String get assetDetailAbout => '简介';

  @override
  String get assetDetailWebsite => '官网';

  @override
  String get assetDetailNotAvailable => '—';

  @override
  String get assetDetailOpenLinkFailed => '无法打开链接。';

  @override
  String get assetDetailPriceChange => '涨跌幅（数据源）';

  @override
  String get communitySortLatest => '最新';

  @override
  String get communitySortPopular => '热门';

  @override
  String communityReplyCount(int count) {
    return '回复：$count';
  }

  @override
  String get assetPostsTitle => '最新讨论';

  @override
  String get assetPostsEmpty => '抢先发布第一条吧。';

  @override
  String get assetPostsPlaceholder => '发表评论…';

  @override
  String get assetPostsReplyPlaceholder => '撰写回复…';

  @override
  String get assetPostsPublish => '发布';

  @override
  String get assetPostsReply => '回复';

  @override
  String get assetPostsReplying => '正在回复';

  @override
  String get assetPostsCancelReply => '取消';

  @override
  String get assetPostsSendError => '发布失败，请重试。';

  @override
  String get assetDetailMoveSummary => '今日异动（AI）';

  @override
  String get assetDetailMoveSummaryDisclaimer => '由公开数据经 AI 生成，仅供参考，不构成投资建议。';

  @override
  String get assetDetailNewsTitle => '头条';

  @override
  String get assetDetailNewsEmpty => '暂无相关头条。';

  @override
  String get assetDetailNewsError => '头条加载失败，请检查网络后重试。';

  @override
  String get assetDetailNewsDisclaimer => '头条来自第三方，仅展示标题与链接。';

  @override
  String get assetDetailNewsShowMore => '展开更多';

  @override
  String get assetDetailNewsShowLess => '收起';

  @override
  String get assetDetailNewsWatchAdAiAnalysis => '观看广告 · AI 新闻解读';

  @override
  String get assetDetailOpenCommunity => '社区';

  @override
  String get communitySearchHint => '搜索帖子中的关键词（任一匹配）…';

  @override
  String get assetDetailOpenChart => '查看图表';

  @override
  String get assetDetailOpenInToss => 'Toss';

  @override
  String get assetDetailOpenInTossTooltip => '在 Toss 证券打开该股票的下单页面';

  @override
  String assetDetailOpenInExchange(String exchange) {
    return '在$exchange查看';
  }

  @override
  String get assetChartRange1mo => '1M';

  @override
  String get assetChartRange3mo => '3M';

  @override
  String get assetChartRange1y => '1Y';

  @override
  String get assetChartFootnote => '日 K 线来自 Yahoo（经服务器）。仅供参考，不构成投资建议。';

  @override
  String get themeDetailChartTitle => '主题指数（归一化）';

  @override
  String get themeDetailChartFootnote =>
      '合成指数：区间内各标的在首日 K 线归一为 100，再按日历日平均。日数据经 Yahoo 与服务器拉取。仅供参考，不构成投资建议。';

  @override
  String get accountSuspendedBanner => '您的账号暂不可在社区发帖、编辑、删除或回复。';

  @override
  String get accountSuspendedSnack => '该账号的社区功能已被限制。';

  @override
  String get shareSheetKakaoTalk => '分享到 KakaoTalk';

  @override
  String get shareSheetSystemShare => '系统分享';

  @override
  String get shareSheetCopyLink => '复制链接';

  @override
  String get shareSheetCopied => '已复制';
}
