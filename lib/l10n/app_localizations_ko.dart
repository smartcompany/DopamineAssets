// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '도파민 자산';

  @override
  String get homeHeaderTitleDecorated => '🔥 도파민 자산 🔥';

  @override
  String get navHome => '홈';

  @override
  String get navRankings => '랭킹';

  @override
  String get navThemes => '테마';

  @override
  String get navMarket => '시장';

  @override
  String get homeHeadline => '지금 시장에서 가장 자극적인 자산';

  @override
  String get rankingsUpTab => '상승 🔥';

  @override
  String get rankingsDownTab => '하락 💀';

  @override
  String get rankingsUpTitle => '오늘 가장 미친 상승';

  @override
  String get rankingsDownTitle => '오늘 가장 크게 박살난 것';

  @override
  String get themesHotTitle => '오늘 가장 미친 테마';

  @override
  String get themesCrashedTitle => '오늘 박살난 테마';

  @override
  String get themesEmergingTitle => '갑자기 뜬 테마';

  @override
  String get marketSummaryTitle => '시장 요약';

  @override
  String get kimchiPremiumLabel => '김치 프리미엄';

  @override
  String get exchangeRateLabel => '환율';

  @override
  String get marketStatusLabel => '시장 상태';

  @override
  String get dopamineScoreLabel => '도파민 점수';

  @override
  String get errorLoadFailed => '불러오지 못했습니다.';

  @override
  String get errorNoApi =>
      'API 주소가 설정되지 않았습니다. 실행 시 --dart-define=API_BASE_URL=... 를 지정하세요.';

  @override
  String get retry => '다시 시도';

  @override
  String get loading => '불러오는 중…';

  @override
  String get emptyState => '표시할 데이터가 없습니다.';

  @override
  String get assetName => '자산';

  @override
  String get priceChangePct => '가격 변동';

  @override
  String get volumeChangePct => '거래량 변동';

  @override
  String get summaryLine => '한줄 요약';

  @override
  String get themeName => '테마';

  @override
  String get themeScore => '테마 점수';

  @override
  String get stockCount => '종목 수';

  @override
  String get sectionRankings => '상승 · 하락';

  @override
  String get sectionThemes => '테마 랭킹';

  @override
  String get sectionMarket => '시장 요약';

  @override
  String get notAvailable => '—';

  @override
  String get homeTopSurgeBadge => 'TOP 10';

  @override
  String get homeKicker => '움직이는 자산만. 지금 돈이 몰리는 곳.';

  @override
  String get homeLiveBadge => '실시간';

  @override
  String homeThemeStockLine(int count) {
    return '$count개 종목';
  }

  @override
  String get assetClassBadgeUsStock => '미국 주식';

  @override
  String get assetClassBadgeKrStock => '한국 주식';

  @override
  String get assetClassBadgeCrypto => '암호화폐';

  @override
  String get assetClassBadgeCommodity => '원자재';

  @override
  String get rankingFilterTitle => '자산 필터';

  @override
  String get rankingFilterConfirm => '확인';

  @override
  String get rankingFilterCancel => '취소';

  @override
  String get rankingFilterNeedOne => '한 개 이상 선택해 주세요.';
}
