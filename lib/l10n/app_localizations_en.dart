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
  String get navRankings => 'Rankings';

  @override
  String get navThemes => 'Themes';

  @override
  String get navMarket => 'Market';

  @override
  String get homeHeadline =>
      'The most stimulating assets in the market right now';

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
  String get assetPostsTitle => 'Posts';

  @override
  String get assetPostsEmpty => 'Be the first to post.';

  @override
  String get assetPostsPlaceholder => 'Share your take on this asset…';

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
}
