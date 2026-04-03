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
  String get favoritesEmpty => '관심 자산이 없습니다.';

  @override
  String get favoritesSignInToSave => '로그인하면 이 기기에서 관심 종목을 저장하고 볼 수 있습니다.';

  @override
  String get navProfile => '프로필';

  @override
  String get profileSignedInSection => '계정';

  @override
  String get profileAccountRefreshTooltip => '프로필·활동 새로고침';

  @override
  String get profileDisplayName => '닉네임';

  @override
  String get profilePhotoTitle => '프로필 사진';

  @override
  String get profilePhotoRemove => '사진 삭제';

  @override
  String get profilePhotoSaved => '프로필 사진을 저장했습니다.';

  @override
  String get profilePhotoRemoved => '프로필 사진을 삭제했습니다.';

  @override
  String get profileEmail => '이메일';

  @override
  String get profileUid => '사용자 ID';

  @override
  String get profileNoEmail => '없음 (소셜 로그인)';

  @override
  String get profileLogout => '로그아웃';

  @override
  String get profileLogoutDone => '로그아웃했습니다.';

  @override
  String get profileDeleteAccount => '탈퇴하기';

  @override
  String get profileDeleteTitle => '탈퇴할까요?';

  @override
  String get profileDeleteMessage => '되돌릴 수 없습니다. Firebase 계정과 로그인 정보가 삭제됩니다.';

  @override
  String get profileDeleteCancel => '취소';

  @override
  String get profileDeleteConfirm => '탈퇴';

  @override
  String get profileDeleteDone => '탈퇴 처리되었습니다.';

  @override
  String get profileRequiresRecentLogin => '보안을 위해 다시 로그인한 뒤 시도해 주세요.';

  @override
  String get profileNotSignedIn => '로그인하면 계정 정보를 볼 수 있습니다.';

  @override
  String get profileSaveDisplayName => '저장';

  @override
  String get profileDisplayNameHint => '게시글에 표시되는 이름';

  @override
  String get profileDisplayNameInputPlaceholder => '닉네임을 입력해 주세요';

  @override
  String get profileCheckDisplayNameDuplicate => '중복 확인';

  @override
  String get profileDisplayNameEmpty => '닉네임을 입력해 주세요.';

  @override
  String get profileDisplayNameCheckFirst => '먼저 중복 확인을 해 주세요.';

  @override
  String get profileNicknameRequiredForCommunity => '프로필에서 닉네임을 설정해 주세요.';

  @override
  String get profilePushTitle => '푸시 알림';

  @override
  String get profileSettingsTitle => '설정';

  @override
  String get profileSettingsLegalDisclosures => '데이터 안내 및 면책';

  @override
  String get profilePushMaster => '전체 알림';

  @override
  String get profilePushSocialReply => '내 글/댓글에 답글';

  @override
  String get profilePushSocialLike => '내 댓글에 좋아요';

  @override
  String get profilePushMarketDaily => '일일 마켓 요약';

  @override
  String get profilePushHotMoverDiscussion => '급등·급락 종목의 활발한 토론';

  @override
  String get profileStatPosts => '게시글';

  @override
  String get profileStatFollowing => '팔로잉';

  @override
  String get profileStatFollowers => '팔로워';

  @override
  String get profileStatBlocked => '차단';

  @override
  String get profileBlockedTitle => '차단한 사용자';

  @override
  String get profileBlockedListEmpty => '차단한 사용자가 없습니다.';

  @override
  String get profileUnblockAction => '차단 해제';

  @override
  String get profileUnblockedDone => '차단을 해제했습니다.';

  @override
  String get profileActivityTitle => '활동 내역';

  @override
  String get profileActivityMyPost => '내가 쓴 글';

  @override
  String profileActivityPostOnAsset(String assetName) {
    return '$assetName 에 쓴 글';
  }

  @override
  String get profileActivityMyReply => '내 답글';

  @override
  String get profileActivityReplyOnPost => '내 글에 달린 댓글';

  @override
  String get profileActivityLikeReceived => '내 댓글에 좋아요';

  @override
  String get profileActivityLikeGiven => '좋아요를 누른 댓글';

  @override
  String get profileActivityEditPost => '수정';

  @override
  String get profileActivityDeletePost => '삭제';

  @override
  String get profileActivityEditDialogTitle => '글 수정';

  @override
  String get profileActivityDeleteDialogTitle => '이 글을 삭제할까요?';

  @override
  String get profileActivityPostDeleted => '삭제되었습니다.';

  @override
  String get profileActivityPostUpdated => '수정되었습니다.';

  @override
  String get profileFollowListEmpty => '아직 없습니다.';

  @override
  String get profileDisplayNameSaved => '닉네임을 저장했습니다.';

  @override
  String get profileDisplayNameTaken => '이 닉네임은 이미 다른 사용자가 사용 중입니다.';

  @override
  String get profileDisplayNameDuplicateFromSocialTitle => '닉네임 확인';

  @override
  String profileDisplayNameDuplicateFromSocialMessage(String name) {
    return '소셜 계정에서 가져온 이름 \"$name\"은(는) 이미 사용 중입니다. 아래에 새 닉네임을 입력한 뒤 중복 확인 후 저장해 주세요.';
  }

  @override
  String get profileDisplayNameDuplicateFromSocialOk => '확인';

  @override
  String get privacyProcessingConsentTitle => '개인정보 수집·이용 동의';

  @override
  String get privacyProcessingConsentLead =>
      '서비스 이용을 위해 아래 내용을 확인하신 뒤 동의해 주세요.';

  @override
  String get privacyProcessingConsentBullet1 =>
      '수집 항목: 계정 식별자(Firebase UID), 이메일(있는 경우), 닉네임·프로필 사진, 게시·댓글·관심 종목 등 서비스 이용 과정에서 생성되는 정보';

  @override
  String get privacyProcessingConsentBullet2 =>
      '이용 목적: 회원 식별, 커뮤니티·피드 제공, 고객 지원, 부정 이용 방지 및 서비스 개선';

  @override
  String get privacyProcessingConsentBullet3 =>
      '보관 및 파기: 탈퇴 시 관련 법령에 따른 보관 의무가 없는 한 지체 없이 삭제·처리합니다.';

  @override
  String get privacyProcessingConsentCheckbox => '위 개인정보 수집·이용에 동의합니다.';

  @override
  String get privacyProcessingConsentAgree => '동의하고 계속하기';

  @override
  String get privacyProcessingConsentDecline => '동의하지 않음';

  @override
  String get profileFollowUnfollow => '언팔로우';

  @override
  String get profileFollowTitleFollowing => '팔로잉';

  @override
  String get profileFollowTitleFollowers => '팔로워';

  @override
  String get communityFollow => '팔로우';

  @override
  String get communityUnfollow => '언팔로우';

  @override
  String get communityOpenAssetDetail => '종목 상세';

  @override
  String get communityMoreMenu => '더보기';

  @override
  String get communityPostSeeMore => '더보기 >';

  @override
  String get communityReportPost => '신고';

  @override
  String get communityBlockAuthor => '사용자 차단';

  @override
  String get communityPostHiddenByReportNotice =>
      '신고 검토로 이 글은 다른 이용자에게 보이지 않습니다.';

  @override
  String get communityBlockAuthorHint =>
      '이 사용자를 차단하면 언팔로우되며, 상대가 쓴 글이 보이지 않습니다.';

  @override
  String get communityBlockAuthorMenuSubtitle => '사용자';

  @override
  String get communityReportPostMenuSubtitle => '이 글';

  @override
  String get communityBlockAuthorShort => '차단';

  @override
  String get communityReportPostShort => '신고';

  @override
  String get communityReportDialogTitle => '이 글을 신고할까요?';

  @override
  String get communityReportReasonHint => '사유 (선택)';

  @override
  String get communityReportSend => '신고';

  @override
  String get communityReportSheetTitle => '신고하기';

  @override
  String get communityReportSheetSubtitle => '신고 사유를 선택해주세요.';

  @override
  String get communityReportReasonSpam => '스팸/광고';

  @override
  String get communityReportReasonAbuse => '욕설/비방/혐오 표현';

  @override
  String get communityReportReasonSexual => '성적/음란한 내용';

  @override
  String get communityReportReasonViolence => '폭력/위협';

  @override
  String get communityReportReasonOther => '기타';

  @override
  String get communityReportDetailHint => '자세한 내용을 적어주세요. (선택)';

  @override
  String get communityReportSubmitButton => '신고 보내기';

  @override
  String get communityReportSubmitted => '신고가 접수되었습니다. 감사합니다.';

  @override
  String get communityBlockAuthorTitle => '이 사용자를 차단할까요?';

  @override
  String communityBlockAuthorMessage(String authorName) {
    return '$authorName님의 글과 프로필이 더 이상 표시되지 않습니다.';
  }

  @override
  String get communityUserBlocked => '차단했습니다.';

  @override
  String get communityLikeLogin => '좋아요하려면 로그인하세요.';

  @override
  String communityLikeCount(int count) {
    return '$count';
  }

  @override
  String communityCommentCount(int count) {
    return '$count';
  }

  @override
  String get communityPostDetailTitle => '본문';

  @override
  String get communityCommentsTitle => '댓글';

  @override
  String get communityWrite => '글쓰기';

  @override
  String get communityComposeTitle => '글쓰기';

  @override
  String get communityComposeSubmit => '게시';

  @override
  String get communityComposeOptionalTitle => '제목 (선택)';

  @override
  String get communityComposeTitleHint => '제목을 입력하거나 비워 두세요';

  @override
  String get communityComposeSymbolLabel => '종목 심볼';

  @override
  String get communityComposeThemePickerLabel => '테마 이름';

  @override
  String get communityComposePickTheme => '테마를 선택하세요';

  @override
  String get communityComposeSymbolHint => '예: TSLA, IBRX';

  @override
  String get communityComposeAssetClassLabel => '자산 유형';

  @override
  String get communityComposeBodyLabel => '본문';

  @override
  String get communityComposeBodyHint =>
      '광고·비난·도배 등 부적절한 글은 삭제될 수 있으며, 반복 시 활동이 제한될 수 있습니다. 건전한 토론을 부탁드립니다.';

  @override
  String get communityComposePhotosLabel => '사진';

  @override
  String get communityComposeNeedSymbol => '종목을 선택해 주세요.';

  @override
  String get communityComposeNeedBody => '본문을 입력해 주세요.';

  @override
  String get communityComposePickSymbol => '종목 선택';

  @override
  String get communityComposeNoRankedSymbols =>
      '이 자산 유형의 랭킹 종목이 없습니다. 홈에서 랭킹을 불러온 뒤 다시 시도해 주세요.';

  @override
  String get communityComposeAddPhotoShort => '사진';

  @override
  String get communityComposeEditTitle => '글 수정';

  @override
  String get communityComposeSave => '저장';

  @override
  String get communityComposeEditReplyTitle => '답글 수정';

  @override
  String ugcBannedWordsMessage(String term) {
    return '허용되지 않는 표현이 포함되어 있습니다: $term';
  }

  @override
  String get navRankings => '랭킹';

  @override
  String get navThemes => '테마';

  @override
  String get navMarket => '시장';

  @override
  String get homeRankingApplyFiltersTooltip => '선택한 필터를 랭킹에 반영합니다';

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
  String get assetClassBadgeTheme => '테마';

  @override
  String get communityComposeThemeNameHint => '테마 이름 (예: 에너지·원자재)';

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
  String assetDetailMarketCapKrwMillions(String amount) {
    return '$amount백만';
  }

  @override
  String assetDetailMarketCapKrwWonFull(String amount) {
    return '$amount원';
  }

  @override
  String get assetDetailMarketCapRank => '시총 랭킹';

  @override
  String get assetDetailCurrentPrice => '현재 가격';

  @override
  String get assetDetailCryptoProfileMore => '더보기';

  @override
  String get assetDetailCryptoProfileLess => '접기';

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
  String get assetPostsTitle => '최근 반응';

  @override
  String get assetPostsEmpty => '첫 게시글을 남겨보세요.';

  @override
  String get assetPostsPlaceholder => '댓글을 남겨 주세요.';

  @override
  String get assetPostsReplyPlaceholder => '답글을 남겨 주세요.';

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
  String get assetDetailNewsWatchAdAiAnalysis => '광고보고 AI 뉴스 분석';

  @override
  String get assetDetailOpenCommunity => '커뮤니티';

  @override
  String get communitySearchHint => '게시글 본문 검색 (OR)…';

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

  @override
  String get themeDetailChartTitle => '테마 평균 추이';

  @override
  String get themeDetailChartFootnote =>
      '구성 종목별로 구간 첫 종가를 100으로 맞춘 뒤, 같은 날짜의 값을 평균한 합성 지수입니다. Yahoo 일봉 · 서버 집계. 투자 권유가 아닙니다.';
}
