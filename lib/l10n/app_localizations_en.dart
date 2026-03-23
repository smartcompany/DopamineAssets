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
}
