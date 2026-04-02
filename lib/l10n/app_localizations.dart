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

  /// No description provided for @actionLogin.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get actionLogin;

  /// No description provided for @navCommunity.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티'**
  String get navCommunity;

  /// No description provided for @favoritesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'관심 자산이 없습니다.'**
  String get favoritesEmpty;

  /// No description provided for @favoritesSignInToSave.
  ///
  /// In ko, this message translates to:
  /// **'로그인하면 이 기기에서 관심 종목을 저장하고 볼 수 있습니다.'**
  String get favoritesSignInToSave;

  /// No description provided for @navProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get navProfile;

  /// No description provided for @profileSignedInSection.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get profileSignedInSection;

  /// No description provided for @profileAccountRefreshTooltip.
  ///
  /// In ko, this message translates to:
  /// **'프로필·활동 새로고침'**
  String get profileAccountRefreshTooltip;

  /// No description provided for @profileDisplayName.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get profileDisplayName;

  /// No description provided for @profilePhotoTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진'**
  String get profilePhotoTitle;

  /// No description provided for @profilePhotoRemove.
  ///
  /// In ko, this message translates to:
  /// **'사진 삭제'**
  String get profilePhotoRemove;

  /// No description provided for @profilePhotoSaved.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진을 저장했습니다.'**
  String get profilePhotoSaved;

  /// No description provided for @profilePhotoRemoved.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진을 삭제했습니다.'**
  String get profilePhotoRemoved;

  /// No description provided for @profileEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get profileEmail;

  /// No description provided for @profileUid.
  ///
  /// In ko, this message translates to:
  /// **'사용자 ID'**
  String get profileUid;

  /// No description provided for @profileNoEmail.
  ///
  /// In ko, this message translates to:
  /// **'없음 (소셜 로그인)'**
  String get profileNoEmail;

  /// No description provided for @profileLogout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get profileLogout;

  /// No description provided for @profileLogoutDone.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃했습니다.'**
  String get profileLogoutDone;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴하기'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴할까요?'**
  String get profileDeleteTitle;

  /// No description provided for @profileDeleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'되돌릴 수 없습니다. Firebase 계정과 로그인 정보가 삭제됩니다.'**
  String get profileDeleteMessage;

  /// No description provided for @profileDeleteCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get profileDeleteCancel;

  /// No description provided for @profileDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴'**
  String get profileDeleteConfirm;

  /// No description provided for @profileDeleteDone.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴 처리되었습니다.'**
  String get profileDeleteDone;

  /// No description provided for @profileRequiresRecentLogin.
  ///
  /// In ko, this message translates to:
  /// **'보안을 위해 다시 로그인한 뒤 시도해 주세요.'**
  String get profileRequiresRecentLogin;

  /// No description provided for @profileNotSignedIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인하면 계정 정보를 볼 수 있습니다.'**
  String get profileNotSignedIn;

  /// No description provided for @profileSaveDisplayName.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get profileSaveDisplayName;

  /// No description provided for @profileDisplayNameHint.
  ///
  /// In ko, this message translates to:
  /// **'게시글에 표시되는 이름'**
  String get profileDisplayNameHint;

  /// No description provided for @profileDisplayNameInputPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해 주세요'**
  String get profileDisplayNameInputPlaceholder;

  /// No description provided for @profileCheckDisplayNameDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'중복 확인'**
  String get profileCheckDisplayNameDuplicate;

  /// No description provided for @profileDisplayNameEmpty.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해 주세요.'**
  String get profileDisplayNameEmpty;

  /// No description provided for @profileDisplayNameCheckFirst.
  ///
  /// In ko, this message translates to:
  /// **'먼저 중복 확인을 해 주세요.'**
  String get profileDisplayNameCheckFirst;

  /// No description provided for @profileNicknameRequiredForCommunity.
  ///
  /// In ko, this message translates to:
  /// **'프로필에서 닉네임을 설정해 주세요.'**
  String get profileNicknameRequiredForCommunity;

  /// No description provided for @profilePushTitle.
  ///
  /// In ko, this message translates to:
  /// **'푸시 알림'**
  String get profilePushTitle;

  /// No description provided for @profileSettingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get profileSettingsTitle;

  /// No description provided for @profileSettingsMoreSoon.
  ///
  /// In ko, this message translates to:
  /// **'추가 설정은 곧 제공됩니다.'**
  String get profileSettingsMoreSoon;

  /// No description provided for @profilePushMaster.
  ///
  /// In ko, this message translates to:
  /// **'전체 알림'**
  String get profilePushMaster;

  /// No description provided for @profilePushSocialReply.
  ///
  /// In ko, this message translates to:
  /// **'내 글/댓글에 답글'**
  String get profilePushSocialReply;

  /// No description provided for @profilePushSocialLike.
  ///
  /// In ko, this message translates to:
  /// **'내 댓글에 좋아요'**
  String get profilePushSocialLike;

  /// No description provided for @profilePushMarketDaily.
  ///
  /// In ko, this message translates to:
  /// **'일일 마켓 요약'**
  String get profilePushMarketDaily;

  /// No description provided for @profileStatPosts.
  ///
  /// In ko, this message translates to:
  /// **'게시글'**
  String get profileStatPosts;

  /// No description provided for @profileStatFollowing.
  ///
  /// In ko, this message translates to:
  /// **'팔로잉'**
  String get profileStatFollowing;

  /// No description provided for @profileStatFollowers.
  ///
  /// In ko, this message translates to:
  /// **'팔로워'**
  String get profileStatFollowers;

  /// No description provided for @profileStatBlocked.
  ///
  /// In ko, this message translates to:
  /// **'차단'**
  String get profileStatBlocked;

  /// No description provided for @profileBlockedTitle.
  ///
  /// In ko, this message translates to:
  /// **'차단한 사용자'**
  String get profileBlockedTitle;

  /// No description provided for @profileBlockedListEmpty.
  ///
  /// In ko, this message translates to:
  /// **'차단한 사용자가 없습니다.'**
  String get profileBlockedListEmpty;

  /// No description provided for @profileUnblockAction.
  ///
  /// In ko, this message translates to:
  /// **'차단 해제'**
  String get profileUnblockAction;

  /// No description provided for @profileUnblockedDone.
  ///
  /// In ko, this message translates to:
  /// **'차단을 해제했습니다.'**
  String get profileUnblockedDone;

  /// No description provided for @profileActivityTitle.
  ///
  /// In ko, this message translates to:
  /// **'활동 내역'**
  String get profileActivityTitle;

  /// No description provided for @profileActivityMyPost.
  ///
  /// In ko, this message translates to:
  /// **'내가 쓴 글'**
  String get profileActivityMyPost;

  /// No description provided for @profileActivityPostOnAsset.
  ///
  /// In ko, this message translates to:
  /// **'{assetName} 에 쓴 글'**
  String profileActivityPostOnAsset(String assetName);

  /// No description provided for @profileActivityMyReply.
  ///
  /// In ko, this message translates to:
  /// **'내 답글'**
  String get profileActivityMyReply;

  /// No description provided for @profileActivityReplyOnPost.
  ///
  /// In ko, this message translates to:
  /// **'내 글에 달린 댓글'**
  String get profileActivityReplyOnPost;

  /// No description provided for @profileActivityLikeReceived.
  ///
  /// In ko, this message translates to:
  /// **'내 댓글에 좋아요'**
  String get profileActivityLikeReceived;

  /// No description provided for @profileActivityLikeGiven.
  ///
  /// In ko, this message translates to:
  /// **'좋아요를 누른 댓글'**
  String get profileActivityLikeGiven;

  /// No description provided for @profileActivityEditPost.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get profileActivityEditPost;

  /// No description provided for @profileActivityDeletePost.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get profileActivityDeletePost;

  /// No description provided for @profileActivityEditDialogTitle.
  ///
  /// In ko, this message translates to:
  /// **'글 수정'**
  String get profileActivityEditDialogTitle;

  /// No description provided for @profileActivityDeleteDialogTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 글을 삭제할까요?'**
  String get profileActivityDeleteDialogTitle;

  /// No description provided for @profileActivityPostDeleted.
  ///
  /// In ko, this message translates to:
  /// **'삭제되었습니다.'**
  String get profileActivityPostDeleted;

  /// No description provided for @profileActivityPostUpdated.
  ///
  /// In ko, this message translates to:
  /// **'수정되었습니다.'**
  String get profileActivityPostUpdated;

  /// No description provided for @profileFollowListEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 없습니다.'**
  String get profileFollowListEmpty;

  /// No description provided for @profileDisplayNameSaved.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 저장했습니다.'**
  String get profileDisplayNameSaved;

  /// No description provided for @profileDisplayNameTaken.
  ///
  /// In ko, this message translates to:
  /// **'이 닉네임은 이미 다른 사용자가 사용 중입니다.'**
  String get profileDisplayNameTaken;

  /// No description provided for @profileDisplayNameDuplicateFromSocialTitle.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 확인'**
  String get profileDisplayNameDuplicateFromSocialTitle;

  /// No description provided for @profileDisplayNameDuplicateFromSocialMessage.
  ///
  /// In ko, this message translates to:
  /// **'소셜 계정에서 가져온 이름 \"{name}\"은(는) 이미 사용 중입니다. 아래에 새 닉네임을 입력한 뒤 중복 확인 후 저장해 주세요.'**
  String profileDisplayNameDuplicateFromSocialMessage(String name);

  /// No description provided for @profileDisplayNameDuplicateFromSocialOk.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get profileDisplayNameDuplicateFromSocialOk;

  /// No description provided for @privacyProcessingConsentTitle.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 수집·이용 동의'**
  String get privacyProcessingConsentTitle;

  /// No description provided for @privacyProcessingConsentLead.
  ///
  /// In ko, this message translates to:
  /// **'서비스 이용을 위해 아래 내용을 확인하신 뒤 동의해 주세요.'**
  String get privacyProcessingConsentLead;

  /// No description provided for @privacyProcessingConsentBullet1.
  ///
  /// In ko, this message translates to:
  /// **'수집 항목: 계정 식별자(Firebase UID), 이메일(있는 경우), 닉네임·프로필 사진, 게시·댓글·관심 종목 등 서비스 이용 과정에서 생성되는 정보'**
  String get privacyProcessingConsentBullet1;

  /// No description provided for @privacyProcessingConsentBullet2.
  ///
  /// In ko, this message translates to:
  /// **'이용 목적: 회원 식별, 커뮤니티·피드 제공, 고객 지원, 부정 이용 방지 및 서비스 개선'**
  String get privacyProcessingConsentBullet2;

  /// No description provided for @privacyProcessingConsentBullet3.
  ///
  /// In ko, this message translates to:
  /// **'보관 및 파기: 탈퇴 시 관련 법령에 따른 보관 의무가 없는 한 지체 없이 삭제·처리합니다.'**
  String get privacyProcessingConsentBullet3;

  /// No description provided for @privacyProcessingConsentCheckbox.
  ///
  /// In ko, this message translates to:
  /// **'위 개인정보 수집·이용에 동의합니다.'**
  String get privacyProcessingConsentCheckbox;

  /// No description provided for @privacyProcessingConsentAgree.
  ///
  /// In ko, this message translates to:
  /// **'동의하고 계속하기'**
  String get privacyProcessingConsentAgree;

  /// No description provided for @privacyProcessingConsentDecline.
  ///
  /// In ko, this message translates to:
  /// **'동의하지 않음'**
  String get privacyProcessingConsentDecline;

  /// No description provided for @profileFollowUnfollow.
  ///
  /// In ko, this message translates to:
  /// **'언팔로우'**
  String get profileFollowUnfollow;

  /// No description provided for @profileFollowTitleFollowing.
  ///
  /// In ko, this message translates to:
  /// **'팔로잉'**
  String get profileFollowTitleFollowing;

  /// No description provided for @profileFollowTitleFollowers.
  ///
  /// In ko, this message translates to:
  /// **'팔로워'**
  String get profileFollowTitleFollowers;

  /// No description provided for @communityFollow.
  ///
  /// In ko, this message translates to:
  /// **'팔로우'**
  String get communityFollow;

  /// No description provided for @communityUnfollow.
  ///
  /// In ko, this message translates to:
  /// **'언팔로우'**
  String get communityUnfollow;

  /// No description provided for @communityOpenAssetDetail.
  ///
  /// In ko, this message translates to:
  /// **'종목 상세'**
  String get communityOpenAssetDetail;

  /// No description provided for @communityMoreMenu.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get communityMoreMenu;

  /// No description provided for @communityPostSeeMore.
  ///
  /// In ko, this message translates to:
  /// **'더보기 >'**
  String get communityPostSeeMore;

  /// No description provided for @communityReportPost.
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get communityReportPost;

  /// No description provided for @communityBlockAuthor.
  ///
  /// In ko, this message translates to:
  /// **'사용자 차단'**
  String get communityBlockAuthor;

  /// No description provided for @communityPostHiddenByReportNotice.
  ///
  /// In ko, this message translates to:
  /// **'신고 검토로 이 글은 다른 이용자에게 보이지 않습니다.'**
  String get communityPostHiddenByReportNotice;

  /// No description provided for @communityBlockAuthorHint.
  ///
  /// In ko, this message translates to:
  /// **'이 사용자를 차단하면 언팔로우되며, 상대가 쓴 글이 보이지 않습니다.'**
  String get communityBlockAuthorHint;

  /// No description provided for @communityBlockAuthorMenuSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get communityBlockAuthorMenuSubtitle;

  /// No description provided for @communityReportPostMenuSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이 글'**
  String get communityReportPostMenuSubtitle;

  /// No description provided for @communityBlockAuthorShort.
  ///
  /// In ko, this message translates to:
  /// **'차단'**
  String get communityBlockAuthorShort;

  /// No description provided for @communityReportPostShort.
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get communityReportPostShort;

  /// No description provided for @communityReportDialogTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 글을 신고할까요?'**
  String get communityReportDialogTitle;

  /// No description provided for @communityReportReasonHint.
  ///
  /// In ko, this message translates to:
  /// **'사유 (선택)'**
  String get communityReportReasonHint;

  /// No description provided for @communityReportSend.
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get communityReportSend;

  /// No description provided for @communityReportSheetTitle.
  ///
  /// In ko, this message translates to:
  /// **'신고하기'**
  String get communityReportSheetTitle;

  /// No description provided for @communityReportSheetSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'신고 사유를 선택해주세요.'**
  String get communityReportSheetSubtitle;

  /// No description provided for @communityReportReasonSpam.
  ///
  /// In ko, this message translates to:
  /// **'스팸/광고'**
  String get communityReportReasonSpam;

  /// No description provided for @communityReportReasonAbuse.
  ///
  /// In ko, this message translates to:
  /// **'욕설/비방/혐오 표현'**
  String get communityReportReasonAbuse;

  /// No description provided for @communityReportReasonSexual.
  ///
  /// In ko, this message translates to:
  /// **'성적/음란한 내용'**
  String get communityReportReasonSexual;

  /// No description provided for @communityReportReasonViolence.
  ///
  /// In ko, this message translates to:
  /// **'폭력/위협'**
  String get communityReportReasonViolence;

  /// No description provided for @communityReportReasonOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get communityReportReasonOther;

  /// No description provided for @communityReportDetailHint.
  ///
  /// In ko, this message translates to:
  /// **'자세한 내용을 적어주세요. (선택)'**
  String get communityReportDetailHint;

  /// No description provided for @communityReportSubmitButton.
  ///
  /// In ko, this message translates to:
  /// **'신고 보내기'**
  String get communityReportSubmitButton;

  /// No description provided for @communityReportSubmitted.
  ///
  /// In ko, this message translates to:
  /// **'신고가 접수되었습니다. 감사합니다.'**
  String get communityReportSubmitted;

  /// No description provided for @communityBlockAuthorTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 사용자를 차단할까요?'**
  String get communityBlockAuthorTitle;

  /// No description provided for @communityBlockAuthorMessage.
  ///
  /// In ko, this message translates to:
  /// **'{authorName}님의 글과 프로필이 더 이상 표시되지 않습니다.'**
  String communityBlockAuthorMessage(String authorName);

  /// No description provided for @communityUserBlocked.
  ///
  /// In ko, this message translates to:
  /// **'차단했습니다.'**
  String get communityUserBlocked;

  /// No description provided for @communityLikeLogin.
  ///
  /// In ko, this message translates to:
  /// **'좋아요하려면 로그인하세요.'**
  String get communityLikeLogin;

  /// No description provided for @communityLikeCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}'**
  String communityLikeCount(int count);

  /// No description provided for @communityCommentCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}'**
  String communityCommentCount(int count);

  /// No description provided for @communityPostDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'본문'**
  String get communityPostDetailTitle;

  /// No description provided for @communityCommentsTitle.
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get communityCommentsTitle;

  /// No description provided for @communityWrite.
  ///
  /// In ko, this message translates to:
  /// **'글쓰기'**
  String get communityWrite;

  /// No description provided for @communityComposeTitle.
  ///
  /// In ko, this message translates to:
  /// **'글쓰기'**
  String get communityComposeTitle;

  /// No description provided for @communityComposeSubmit.
  ///
  /// In ko, this message translates to:
  /// **'게시'**
  String get communityComposeSubmit;

  /// No description provided for @communityComposeOptionalTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목 (선택)'**
  String get communityComposeOptionalTitle;

  /// No description provided for @communityComposeTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력하거나 비워 두세요'**
  String get communityComposeTitleHint;

  /// No description provided for @communityComposeSymbolLabel.
  ///
  /// In ko, this message translates to:
  /// **'종목 심볼'**
  String get communityComposeSymbolLabel;

  /// No description provided for @communityComposeThemePickerLabel.
  ///
  /// In ko, this message translates to:
  /// **'테마 이름'**
  String get communityComposeThemePickerLabel;

  /// No description provided for @communityComposePickTheme.
  ///
  /// In ko, this message translates to:
  /// **'테마를 선택하세요'**
  String get communityComposePickTheme;

  /// No description provided for @communityComposeSymbolHint.
  ///
  /// In ko, this message translates to:
  /// **'예: TSLA, IBRX'**
  String get communityComposeSymbolHint;

  /// No description provided for @communityComposeAssetClassLabel.
  ///
  /// In ko, this message translates to:
  /// **'자산 유형'**
  String get communityComposeAssetClassLabel;

  /// No description provided for @communityComposeBodyLabel.
  ///
  /// In ko, this message translates to:
  /// **'본문'**
  String get communityComposeBodyLabel;

  /// No description provided for @communityComposeBodyHint.
  ///
  /// In ko, this message translates to:
  /// **'광고·비난·도배 등 부적절한 글은 삭제될 수 있으며, 반복 시 활동이 제한될 수 있습니다. 건전한 토론을 부탁드립니다.'**
  String get communityComposeBodyHint;

  /// No description provided for @communityComposePhotosLabel.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get communityComposePhotosLabel;

  /// No description provided for @communityComposeNeedSymbol.
  ///
  /// In ko, this message translates to:
  /// **'종목을 선택해 주세요.'**
  String get communityComposeNeedSymbol;

  /// No description provided for @communityComposeNeedBody.
  ///
  /// In ko, this message translates to:
  /// **'본문을 입력해 주세요.'**
  String get communityComposeNeedBody;

  /// No description provided for @communityComposePickSymbol.
  ///
  /// In ko, this message translates to:
  /// **'종목 선택'**
  String get communityComposePickSymbol;

  /// No description provided for @communityComposeNoRankedSymbols.
  ///
  /// In ko, this message translates to:
  /// **'이 자산 유형의 랭킹 종목이 없습니다. 홈에서 랭킹을 불러온 뒤 다시 시도해 주세요.'**
  String get communityComposeNoRankedSymbols;

  /// No description provided for @communityComposeAddPhotoShort.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get communityComposeAddPhotoShort;

  /// No description provided for @communityComposeEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'글 수정'**
  String get communityComposeEditTitle;

  /// No description provided for @communityComposeSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get communityComposeSave;

  /// No description provided for @communityComposeEditReplyTitle.
  ///
  /// In ko, this message translates to:
  /// **'답글 수정'**
  String get communityComposeEditReplyTitle;

  /// No description provided for @ugcBannedWordsMessage.
  ///
  /// In ko, this message translates to:
  /// **'허용되지 않는 표현이 포함되어 있습니다: {term}'**
  String ugcBannedWordsMessage(String term);

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

  /// No description provided for @homeRankingApplyFiltersTooltip.
  ///
  /// In ko, this message translates to:
  /// **'선택한 필터를 랭킹에 반영합니다'**
  String get homeRankingApplyFiltersTooltip;

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

  /// No description provided for @assetClassBadgeTheme.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get assetClassBadgeTheme;

  /// No description provided for @communityComposeThemeNameHint.
  ///
  /// In ko, this message translates to:
  /// **'테마 이름 (예: 에너지·원자재)'**
  String get communityComposeThemeNameHint;

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

  /// No description provided for @assetDetailMarketCapKrwMillions.
  ///
  /// In ko, this message translates to:
  /// **'{amount}백만'**
  String assetDetailMarketCapKrwMillions(String amount);

  /// No description provided for @assetDetailMarketCapKrwWonFull.
  ///
  /// In ko, this message translates to:
  /// **'{amount}원'**
  String assetDetailMarketCapKrwWonFull(String amount);

  /// No description provided for @assetDetailMarketCapRank.
  ///
  /// In ko, this message translates to:
  /// **'시총 랭킹'**
  String get assetDetailMarketCapRank;

  /// No description provided for @assetDetailCurrentPrice.
  ///
  /// In ko, this message translates to:
  /// **'현재 가격'**
  String get assetDetailCurrentPrice;

  /// No description provided for @assetDetailCryptoProfileMore.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get assetDetailCryptoProfileMore;

  /// No description provided for @assetDetailCryptoProfileLess.
  ///
  /// In ko, this message translates to:
  /// **'접기'**
  String get assetDetailCryptoProfileLess;

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

  /// No description provided for @communitySortLatest.
  ///
  /// In ko, this message translates to:
  /// **'최신순'**
  String get communitySortLatest;

  /// No description provided for @communitySortPopular.
  ///
  /// In ko, this message translates to:
  /// **'인기순'**
  String get communitySortPopular;

  /// No description provided for @communityReplyCount.
  ///
  /// In ko, this message translates to:
  /// **'답글 {count}개'**
  String communityReplyCount(int count);

  /// No description provided for @assetPostsTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 반응'**
  String get assetPostsTitle;

  /// No description provided for @assetPostsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'첫 게시글을 남겨보세요.'**
  String get assetPostsEmpty;

  /// No description provided for @assetPostsPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 남겨 주세요.'**
  String get assetPostsPlaceholder;

  /// No description provided for @assetPostsReplyPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'답글을 남겨 주세요.'**
  String get assetPostsReplyPlaceholder;

  /// No description provided for @assetPostsPublish.
  ///
  /// In ko, this message translates to:
  /// **'등록'**
  String get assetPostsPublish;

  /// No description provided for @assetPostsReply.
  ///
  /// In ko, this message translates to:
  /// **'답글'**
  String get assetPostsReply;

  /// No description provided for @assetPostsReplying.
  ///
  /// In ko, this message translates to:
  /// **'답글 작성 중'**
  String get assetPostsReplying;

  /// No description provided for @assetPostsCancelReply.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get assetPostsCancelReply;

  /// No description provided for @assetPostsSendError.
  ///
  /// In ko, this message translates to:
  /// **'게시글을 등록하지 못했습니다.'**
  String get assetPostsSendError;

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

  /// No description provided for @assetDetailNewsWatchAdAiAnalysis.
  ///
  /// In ko, this message translates to:
  /// **'광고보고 AI 뉴스 분석'**
  String get assetDetailNewsWatchAdAiAnalysis;

  /// No description provided for @assetDetailOpenCommunity.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티'**
  String get assetDetailOpenCommunity;

  /// No description provided for @communitySearchHint.
  ///
  /// In ko, this message translates to:
  /// **'게시글 본문 검색 (OR)…'**
  String get communitySearchHint;

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

  /// No description provided for @themeDetailChartTitle.
  ///
  /// In ko, this message translates to:
  /// **'테마 평균 추이'**
  String get themeDetailChartTitle;

  /// No description provided for @themeDetailChartFootnote.
  ///
  /// In ko, this message translates to:
  /// **'구성 종목별로 구간 첫 종가를 100으로 맞춘 뒤, 같은 날짜의 값을 평균한 합성 지수입니다. Yahoo 일봉 · 서버 집계. 투자 권유가 아닙니다.'**
  String get themeDetailChartFootnote;
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
