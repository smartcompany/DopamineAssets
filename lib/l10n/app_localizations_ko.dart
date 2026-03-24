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
  String get actionLogin => '로그인';

  @override
  String get navCommunity => '커뮤니티';

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

  @override
  String get assetDetailMissingClass => '자산 분류 정보가 없어 상세를 열 수 없습니다.';

  @override
  String get assetDetailSectionProfile => '개요';

  @override
  String get assetDetailMarketCap => '시가총액';

  @override
  String get assetDetailSector => '섹터';

  @override
  String get assetDetailIndustry => '산업';

  @override
  String get assetDetailExchange => '거래소';

  @override
  String get assetDetailCurrency => '통화';

  @override
  String get assetDetailPair => '거래쌍';

  @override
  String get assetDetailAbout => '소개';

  @override
  String get assetDetailWebsite => '웹사이트';

  @override
  String get assetDetailNotAvailable => '—';

  @override
  String get assetDetailOpenLinkFailed => '링크를 열 수 없습니다.';

  @override
  String get assetDetailPriceChange => '가격 변동 (피드)';

  @override
  String get communitySortLatest => '최신순';

  @override
  String get communitySortPopular => '인기순';

  @override
  String communityReplyCount(int count) {
    return '답글 $count개';
  }

  @override
  String get assetPostsTitle => '게시글';

  @override
  String get assetPostsEmpty => '첫 게시글을 남겨보세요.';

  @override
  String get assetPostsPlaceholder => '이 자산에 대한 생각을 남겨보세요…';

  @override
  String get assetPostsPublish => '등록';

  @override
  String get assetPostsReply => '답글';

  @override
  String get assetPostsReplying => '답글 작성 중';

  @override
  String get assetPostsCancelReply => '취소';

  @override
  String get assetPostsSendError => '게시글을 등록하지 못했습니다.';

  @override
  String get assetDetailMoveSummary => '오늘 움직임 요약';

  @override
  String get assetDetailMoveSummaryDisclaimer =>
      'AI가 공개 수치만으로 생성한 참고용 문장이며, 투자 권유가 아닙니다.';

  @override
  String get assetDetailNewsTitle => '뉴스';

  @override
  String get assetDetailNewsEmpty => '이 검색으로 최근 헤드라인이 없습니다.';

  @override
  String get assetDetailNewsError => '뉴스를 불러오지 못했습니다. 연결을 확인하거나 다시 시도해 주세요.';

  @override
  String get assetDetailNewsDisclaimer => '외부 뉴스 소스의 제목·링크만 표시합니다.';

  @override
  String get assetDetailNewsShowMore => '더 보기';

  @override
  String get assetDetailNewsShowLess => '접기';

  @override
  String get assetDetailOpenChart => '차트 보기';

  @override
  String get assetChartRange1mo => '1M';

  @override
  String get assetChartRange3mo => '3M';

  @override
  String get assetChartRange1y => '1Y';

  @override
  String get assetChartFootnote => '일봉 캔들 · Yahoo 데이터(서버 경유). 투자 권유가 아닙니다.';
}
