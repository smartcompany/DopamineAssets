import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'도파민 자산'**
  String get appTitle;

  /// No description provided for @homeHeaderTitleDecorated.
  ///
  /// In ko, this message translates to:
  /// **'🔥 도파민 자산 🔥'**
  String get homeHeaderTitleDecorated;

  /// No description provided for @navHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// No description provided for @navRankings.
  ///
  /// In ko, this message translates to:
  /// **'랭킹'**
  String get navRankings;

  /// No description provided for @navThemes.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get navThemes;

  /// No description provided for @navMarket.
  ///
  /// In ko, this message translates to:
  /// **'시장'**
  String get navMarket;

  /// No description provided for @homeHeadline.
  ///
  /// In ko, this message translates to:
  /// **'지금 시장에서 가장 자극적인 자산'**
  String get homeHeadline;

  /// No description provided for @rankingsUpTab.
  ///
  /// In ko, this message translates to:
  /// **'상승 🔥'**
  String get rankingsUpTab;

  /// No description provided for @rankingsDownTab.
  ///
  /// In ko, this message translates to:
  /// **'하락 💀'**
  String get rankingsDownTab;

  /// No description provided for @rankingsUpTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘 가장 미친 상승'**
  String get rankingsUpTitle;

  /// No description provided for @rankingsDownTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘 가장 크게 박살난 것'**
  String get rankingsDownTitle;

  /// No description provided for @themesHotTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘 가장 미친 테마'**
  String get themesHotTitle;

  /// No description provided for @themesCrashedTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘 박살난 테마'**
  String get themesCrashedTitle;

  /// No description provided for @themesEmergingTitle.
  ///
  /// In ko, this message translates to:
  /// **'갑자기 뜬 테마'**
  String get themesEmergingTitle;

  /// No description provided for @marketSummaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'시장 요약'**
  String get marketSummaryTitle;

  /// No description provided for @kimchiPremiumLabel.
  ///
  /// In ko, this message translates to:
  /// **'김치 프리미엄'**
  String get kimchiPremiumLabel;

  /// No description provided for @exchangeRateLabel.
  ///
  /// In ko, this message translates to:
  /// **'환율'**
  String get exchangeRateLabel;

  /// No description provided for @marketStatusLabel.
  ///
  /// In ko, this message translates to:
  /// **'시장 상태'**
  String get marketStatusLabel;

  /// No description provided for @dopamineScoreLabel.
  ///
  /// In ko, this message translates to:
  /// **'도파민 점수'**
  String get dopamineScoreLabel;

  /// No description provided for @errorLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'불러오지 못했습니다.'**
  String get errorLoadFailed;

  /// No description provided for @errorNoApi.
  ///
  /// In ko, this message translates to:
  /// **'API 주소가 설정되지 않았습니다. 실행 시 --dart-define=API_BASE_URL=... 를 지정하세요.'**
  String get errorNoApi;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In ko, this message translates to:
  /// **'불러오는 중…'**
  String get loading;

  /// No description provided for @emptyState.
  ///
  /// In ko, this message translates to:
  /// **'표시할 데이터가 없습니다.'**
  String get emptyState;

  /// No description provided for @assetName.
  ///
  /// In ko, this message translates to:
  /// **'자산'**
  String get assetName;

  /// No description provided for @priceChangePct.
  ///
  /// In ko, this message translates to:
  /// **'가격 변동'**
  String get priceChangePct;

  /// No description provided for @volumeChangePct.
  ///
  /// In ko, this message translates to:
  /// **'거래량 변동'**
  String get volumeChangePct;

  /// No description provided for @summaryLine.
  ///
  /// In ko, this message translates to:
  /// **'한줄 요약'**
  String get summaryLine;

  /// No description provided for @themeName.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get themeName;

  /// No description provided for @themeScore.
  ///
  /// In ko, this message translates to:
  /// **'테마 점수'**
  String get themeScore;

  /// No description provided for @stockCount.
  ///
  /// In ko, this message translates to:
  /// **'종목 수'**
  String get stockCount;

  /// No description provided for @sectionRankings.
  ///
  /// In ko, this message translates to:
  /// **'상승 · 하락'**
  String get sectionRankings;

  /// No description provided for @sectionThemes.
  ///
  /// In ko, this message translates to:
  /// **'테마 랭킹'**
  String get sectionThemes;

  /// No description provided for @sectionMarket.
  ///
  /// In ko, this message translates to:
  /// **'시장 요약'**
  String get sectionMarket;

  /// No description provided for @notAvailable.
  ///
  /// In ko, this message translates to:
  /// **'—'**
  String get notAvailable;

  /// No description provided for @homeTopSurgeBadge.
  ///
  /// In ko, this message translates to:
  /// **'TOP 10'**
  String get homeTopSurgeBadge;

  /// No description provided for @homeKicker.
  ///
  /// In ko, this message translates to:
  /// **'움직이는 자산만. 지금 돈이 몰리는 곳.'**
  String get homeKicker;

  /// No description provided for @homeLiveBadge.
  ///
  /// In ko, this message translates to:
  /// **'실시간'**
  String get homeLiveBadge;

  /// No description provided for @homeThemeStockLine.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 종목'**
  String homeThemeStockLine(int count);

  /// No description provided for @assetClassBadgeUsStock.
  ///
  /// In ko, this message translates to:
  /// **'미국 주식'**
  String get assetClassBadgeUsStock;

  /// No description provided for @assetClassBadgeKrStock.
  ///
  /// In ko, this message translates to:
  /// **'한국 주식'**
  String get assetClassBadgeKrStock;

  /// No description provided for @assetClassBadgeCrypto.
  ///
  /// In ko, this message translates to:
  /// **'암호화폐'**
  String get assetClassBadgeCrypto;

  /// No description provided for @assetClassBadgeCommodity.
  ///
  /// In ko, this message translates to:
  /// **'원자재'**
  String get assetClassBadgeCommodity;

  /// No description provided for @rankingFilterTitle.
  ///
  /// In ko, this message translates to:
  /// **'자산 필터'**
  String get rankingFilterTitle;

  /// No description provided for @rankingFilterConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get rankingFilterConfirm;

  /// No description provided for @rankingFilterCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get rankingFilterCancel;

  /// No description provided for @rankingFilterNeedOne.
  ///
  /// In ko, this message translates to:
  /// **'한 개 이상 선택해 주세요.'**
  String get rankingFilterNeedOne;

  /// No description provided for @assetDetailMissingClass.
  ///
  /// In ko, this message translates to:
  /// **'자산 분류 정보가 없어 상세를 열 수 없습니다.'**
  String get assetDetailMissingClass;

  /// No description provided for @assetDetailSectionProfile.
  ///
  /// In ko, this message translates to:
  /// **'개요'**
  String get assetDetailSectionProfile;

  /// No description provided for @assetDetailMarketCap.
  ///
  /// In ko, this message translates to:
  /// **'시가총액'**
  String get assetDetailMarketCap;

  /// No description provided for @assetDetailSector.
  ///
  /// In ko, this message translates to:
  /// **'섹터'**
  String get assetDetailSector;

  /// No description provided for @assetDetailIndustry.
  ///
  /// In ko, this message translates to:
  /// **'산업'**
  String get assetDetailIndustry;

  /// No description provided for @assetDetailExchange.
  ///
  /// In ko, this message translates to:
  /// **'거래소'**
  String get assetDetailExchange;

  /// No description provided for @assetDetailCurrency.
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get assetDetailCurrency;

  /// No description provided for @assetDetailPair.
  ///
  /// In ko, this message translates to:
  /// **'거래쌍'**
  String get assetDetailPair;

  /// No description provided for @assetDetailAbout.
  ///
  /// In ko, this message translates to:
  /// **'소개'**
  String get assetDetailAbout;

  /// No description provided for @assetDetailWebsite.
  ///
  /// In ko, this message translates to:
  /// **'웹사이트'**
  String get assetDetailWebsite;

  /// No description provided for @assetDetailNotAvailable.
  ///
  /// In ko, this message translates to:
  /// **'—'**
  String get assetDetailNotAvailable;

  /// No description provided for @assetDetailOpenLinkFailed.
  ///
  /// In ko, this message translates to:
  /// **'링크를 열 수 없습니다.'**
  String get assetDetailOpenLinkFailed;

  /// No description provided for @assetDetailPriceChange.
  ///
  /// In ko, this message translates to:
  /// **'가격 변동 (피드)'**
  String get assetDetailPriceChange;

  /// No description provided for @assetCommentsTitle.
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get assetCommentsTitle;

  /// No description provided for @assetCommentsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'첫 댓글을 남겨보세요.'**
  String get assetCommentsEmpty;

  /// No description provided for @assetCommentsPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'지금 이 자산에 대한 생각을 남겨보세요…'**
  String get assetCommentsPlaceholder;

  /// No description provided for @assetCommentsPost.
  ///
  /// In ko, this message translates to:
  /// **'등록'**
  String get assetCommentsPost;

  /// No description provided for @assetCommentsReply.
  ///
  /// In ko, this message translates to:
  /// **'답글'**
  String get assetCommentsReply;

  /// No description provided for @assetCommentsReplying.
  ///
  /// In ko, this message translates to:
  /// **'답글 작성 중'**
  String get assetCommentsReplying;

  /// No description provided for @assetCommentsCancelReply.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get assetCommentsCancelReply;

  /// No description provided for @assetCommentsSendError.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 보내지 못했습니다.'**
  String get assetCommentsSendError;

  /// No description provided for @assetDetailMoveSummary.
  ///
  /// In ko, this message translates to:
  /// **'오늘 움직임 요약'**
  String get assetDetailMoveSummary;

  /// No description provided for @assetDetailMoveSummaryDisclaimer.
  ///
  /// In ko, this message translates to:
  /// **'AI가 공개 수치만으로 생성한 참고용 문장이며, 투자 권유가 아닙니다.'**
  String get assetDetailMoveSummaryDisclaimer;

  /// No description provided for @assetDetailNewsTitle.
  ///
  /// In ko, this message translates to:
  /// **'뉴스'**
  String get assetDetailNewsTitle;

  /// No description provided for @assetDetailNewsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 검색으로 최근 헤드라인이 없습니다.'**
  String get assetDetailNewsEmpty;

  /// No description provided for @assetDetailNewsError.
  ///
  /// In ko, this message translates to:
  /// **'뉴스를 불러오지 못했습니다. 연결을 확인하거나 다시 시도해 주세요.'**
  String get assetDetailNewsError;

  /// No description provided for @assetDetailNewsDisclaimer.
  ///
  /// In ko, this message translates to:
  /// **'외부 뉴스 소스의 제목·링크만 표시합니다.'**
  String get assetDetailNewsDisclaimer;

  /// No description provided for @assetDetailNewsShowMore.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get assetDetailNewsShowMore;

  /// No description provided for @assetDetailNewsShowLess.
  ///
  /// In ko, this message translates to:
  /// **'접기'**
  String get assetDetailNewsShowLess;

  /// No description provided for @assetDetailOpenChart.
  ///
  /// In ko, this message translates to:
  /// **'차트 보기'**
  String get assetDetailOpenChart;

  /// No description provided for @assetChartRange1mo.
  ///
  /// In ko, this message translates to:
  /// **'1M'**
  String get assetChartRange1mo;

  /// No description provided for @assetChartRange3mo.
  ///
  /// In ko, this message translates to:
  /// **'3M'**
  String get assetChartRange3mo;

  /// No description provided for @assetChartRange1y.
  ///
  /// In ko, this message translates to:
  /// **'1Y'**
  String get assetChartRange1y;

  /// No description provided for @assetChartFootnote.
  ///
  /// In ko, this message translates to:
  /// **'일봉 캔들 · Yahoo 데이터(서버 경유). 투자 권유가 아닙니다.'**
  String get assetChartFootnote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
