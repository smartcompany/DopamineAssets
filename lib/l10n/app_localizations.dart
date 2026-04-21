import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

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
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Dopamine Assets'**
  String get appTitle;

  /// No description provided for @homeHeaderTitleDecorated.
  ///
  /// In en, this message translates to:
  /// **'Dopamine Assets'**
  String get homeHeaderTitleDecorated;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @actionLogin.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get actionLogin;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved favorites yet.'**
  String get favoritesEmpty;

  /// No description provided for @favoritesSignInToSave.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save and view favorites on this device.'**
  String get favoritesSignInToSave;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @profileSignedInSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileSignedInSection;

  /// No description provided for @profileAccountRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh profile and activity'**
  String get profileAccountRefreshTooltip;

  /// No description provided for @profileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayName;

  /// No description provided for @profilePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhotoTitle;

  /// No description provided for @profilePhotoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profilePhotoRemove;

  /// No description provided for @profilePhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo saved.'**
  String get profilePhotoSaved;

  /// No description provided for @profilePhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed.'**
  String get profilePhotoRemoved;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileUid.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get profileUid;

  /// No description provided for @profileNoEmail.
  ///
  /// In en, this message translates to:
  /// **'Not set (social login)'**
  String get profileNoEmail;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogout;

  /// No description provided for @profileLogoutDone.
  ///
  /// In en, this message translates to:
  /// **'Signed out.'**
  String get profileLogoutDone;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get profileDeleteTitle;

  /// No description provided for @profileDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Your Firebase account and sign-in will be removed.'**
  String get profileDeleteMessage;

  /// No description provided for @profileDeleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileDeleteCancel;

  /// No description provided for @profileDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get profileDeleteConfirm;

  /// No description provided for @profileDeleteDone.
  ///
  /// In en, this message translates to:
  /// **'Account deleted.'**
  String get profileDeleteDone;

  /// No description provided for @profileRequiresRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again and retry (security).'**
  String get profileRequiresRecentLogin;

  /// No description provided for @profileNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your account.'**
  String get profileNotSignedIn;

  /// No description provided for @profileSaveDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSaveDisplayName;

  /// No description provided for @profileDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'How your name appears on posts'**
  String get profileDisplayNameHint;

  /// No description provided for @profileDisplayNameInputPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter a display name'**
  String get profileDisplayNameInputPlaceholder;

  /// No description provided for @profileCheckDisplayNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Check availability'**
  String get profileCheckDisplayNameDuplicate;

  /// No description provided for @profileDisplayNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a display name.'**
  String get profileDisplayNameEmpty;

  /// No description provided for @profileDisplayNameCheckFirst.
  ///
  /// In en, this message translates to:
  /// **'Check availability before saving.'**
  String get profileDisplayNameCheckFirst;

  /// No description provided for @profileNicknameRequiredForCommunity.
  ///
  /// In en, this message translates to:
  /// **'Set your display name in Profile.'**
  String get profileNicknameRequiredForCommunity;

  /// No description provided for @profilePushTitle.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get profilePushTitle;

  /// No description provided for @profileSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettingsTitle;

  /// No description provided for @profileSettingsLegalDisclosures.
  ///
  /// In en, this message translates to:
  /// **'Data sources & disclaimers'**
  String get profileSettingsLegalDisclosures;

  /// No description provided for @profilePushMaster.
  ///
  /// In en, this message translates to:
  /// **'All notifications'**
  String get profilePushMaster;

  /// No description provided for @profilePushSocialReply.
  ///
  /// In en, this message translates to:
  /// **'Replies to my posts/comments'**
  String get profilePushSocialReply;

  /// No description provided for @profilePushSocialLike.
  ///
  /// In en, this message translates to:
  /// **'Likes on my comments'**
  String get profilePushSocialLike;

  /// No description provided for @profilePushMarketDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily market summary'**
  String get profilePushMarketDaily;

  /// No description provided for @profilePushHotMoverDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Hot movers — lively discussions'**
  String get profilePushHotMoverDiscussion;

  /// No description provided for @profileStatPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get profileStatPosts;

  /// No description provided for @profileStatFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get profileStatFollowing;

  /// No description provided for @profileStatFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get profileStatFollowers;

  /// No description provided for @profileStatBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get profileStatBlocked;

  /// No description provided for @profileBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get profileBlockedTitle;

  /// No description provided for @profileBlockedListEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not blocked anyone.'**
  String get profileBlockedListEmpty;

  /// No description provided for @profileUnblockAction.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get profileUnblockAction;

  /// No description provided for @profileUnblockedDone.
  ///
  /// In en, this message translates to:
  /// **'Unblocked.'**
  String get profileUnblockedDone;

  /// No description provided for @profileActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get profileActivityTitle;

  /// No description provided for @profileActivityMyPost.
  ///
  /// In en, this message translates to:
  /// **'Your post'**
  String get profileActivityMyPost;

  /// No description provided for @profileActivityPostOnAsset.
  ///
  /// In en, this message translates to:
  /// **'Post on {assetName}'**
  String profileActivityPostOnAsset(String assetName);

  /// No description provided for @profileActivityMyReply.
  ///
  /// In en, this message translates to:
  /// **'Your reply'**
  String get profileActivityMyReply;

  /// No description provided for @profileActivityReplyOnPost.
  ///
  /// In en, this message translates to:
  /// **'Reply on your post'**
  String get profileActivityReplyOnPost;

  /// No description provided for @profileActivityLikeReceived.
  ///
  /// In en, this message translates to:
  /// **'Like on your comment'**
  String get profileActivityLikeReceived;

  /// No description provided for @profileActivityLikeGiven.
  ///
  /// In en, this message translates to:
  /// **'You liked a comment'**
  String get profileActivityLikeGiven;

  /// No description provided for @profileActivityEditPost.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileActivityEditPost;

  /// No description provided for @profileActivityDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get profileActivityDeletePost;

  /// No description provided for @profileActivityEditDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get profileActivityEditDialogTitle;

  /// No description provided for @profileActivityDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this post?'**
  String get profileActivityDeleteDialogTitle;

  /// No description provided for @profileActivityPostDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted.'**
  String get profileActivityPostDeleted;

  /// No description provided for @profileActivityPostUpdated.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get profileActivityPostUpdated;

  /// No description provided for @profileFollowListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No users yet.'**
  String get profileFollowListEmpty;

  /// No description provided for @profileDisplayNameSaved.
  ///
  /// In en, this message translates to:
  /// **'Display name updated.'**
  String get profileDisplayNameSaved;

  /// No description provided for @profileDisplayNameTaken.
  ///
  /// In en, this message translates to:
  /// **'This display name is already taken.'**
  String get profileDisplayNameTaken;

  /// No description provided for @profileDisplayNameDuplicateFromSocialTitle.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayNameDuplicateFromSocialTitle;

  /// No description provided for @profileDisplayNameDuplicateFromSocialMessage.
  ///
  /// In en, this message translates to:
  /// **'The name from your sign-in provider, \"{name}\", is already in use. Enter a new name below, tap Check availability, then Save.'**
  String profileDisplayNameDuplicateFromSocialMessage(String name);

  /// No description provided for @profileDisplayNameDuplicateFromSocialOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get profileDisplayNameDuplicateFromSocialOk;

  /// No description provided for @privacyProcessingConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms, community & privacy'**
  String get privacyProcessingConsentTitle;

  /// No description provided for @privacyProcessingConsentLead.
  ///
  /// In en, this message translates to:
  /// **'To use the service—including community and other user-generated content—please read and accept the following before continuing.'**
  String get privacyProcessingConsentLead;

  /// No description provided for @privacyProcessingConsentSectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Personal data'**
  String get privacyProcessingConsentSectionPrivacy;

  /// No description provided for @privacyProcessingConsentSectionCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community & user-generated content (UGC)'**
  String get privacyProcessingConsentSectionCommunity;

  /// No description provided for @privacyProcessingConsentUgcIntro.
  ///
  /// In en, this message translates to:
  /// **'These rules apply before you access posts, comments, and other UGC:'**
  String get privacyProcessingConsentUgcIntro;

  /// No description provided for @privacyProcessingConsentBullet1.
  ///
  /// In en, this message translates to:
  /// **'Data collected: account identifier (Firebase UID), email if provided, display name and profile photo, and information generated through use such as posts, comments, and watchlists.'**
  String get privacyProcessingConsentBullet1;

  /// No description provided for @privacyProcessingConsentBullet2.
  ///
  /// In en, this message translates to:
  /// **'Purposes: identification, community and feed features, support, abuse prevention, and service improvement.'**
  String get privacyProcessingConsentBullet2;

  /// No description provided for @privacyProcessingConsentBullet3.
  ///
  /// In en, this message translates to:
  /// **'Retention: we delete or anonymize data when you delete your account, except where law requires longer retention.'**
  String get privacyProcessingConsentBullet3;

  /// No description provided for @privacyProcessingConsentUgcBullet1.
  ///
  /// In en, this message translates to:
  /// **'Zero tolerance: objectionable content is not allowed. This includes unlawful material, harassment, hate, non-consensual sexual content, violence, threats, spam, scams, and similar abuse.'**
  String get privacyProcessingConsentUgcBullet1;

  /// No description provided for @privacyProcessingConsentUgcBullet2.
  ///
  /// In en, this message translates to:
  /// **'Abusive users are not tolerated. We may remove content, limit features, or suspend or terminate accounts that break these rules.'**
  String get privacyProcessingConsentUgcBullet2;

  /// No description provided for @privacyProcessingConsentUgcBullet3.
  ///
  /// In en, this message translates to:
  /// **'You can report objectionable posts and block users from the menus on posts and in profiles. Please use report and block if you see harmful content or behavior.'**
  String get privacyProcessingConsentUgcBullet3;

  /// No description provided for @privacyProcessingConsentCheckboxPrivacy.
  ///
  /// In en, this message translates to:
  /// **'I agree to the collection and use of my personal data as described in the Personal data section above.'**
  String get privacyProcessingConsentCheckboxPrivacy;

  /// No description provided for @privacyProcessingConsentCheckboxCommunity.
  ///
  /// In en, this message translates to:
  /// **'I agree to the community and UGC rules above, including zero tolerance for objectionable content and abusive users.'**
  String get privacyProcessingConsentCheckboxCommunity;

  /// No description provided for @privacyProcessingConsentAgree.
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get privacyProcessingConsentAgree;

  /// No description provided for @privacyProcessingConsentDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get privacyProcessingConsentDecline;

  /// No description provided for @profileFollowUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get profileFollowUnfollow;

  /// No description provided for @profileFollowTitleFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get profileFollowTitleFollowing;

  /// No description provided for @profileFollowTitleFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get profileFollowTitleFollowers;

  /// No description provided for @communityFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get communityFollow;

  /// No description provided for @communityUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get communityUnfollow;

  /// No description provided for @communityOpenAssetDetail.
  ///
  /// In en, this message translates to:
  /// **'Asset details'**
  String get communityOpenAssetDetail;

  /// No description provided for @communityMoreMenu.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get communityMoreMenu;

  /// No description provided for @communityPostSeeMore.
  ///
  /// In en, this message translates to:
  /// **'See more >'**
  String get communityPostSeeMore;

  /// No description provided for @communityShowOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show original'**
  String get communityShowOriginal;

  /// No description provided for @communityShowTranslated.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get communityShowTranslated;

  /// No description provided for @communityReportPost.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get communityReportPost;

  /// No description provided for @communityBlockAuthor.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get communityBlockAuthor;

  /// No description provided for @communityPostHiddenByReportNotice.
  ///
  /// In en, this message translates to:
  /// **'This post is hidden from other users after a report review.'**
  String get communityPostHiddenByReportNotice;

  /// No description provided for @communityBlockAuthorHint.
  ///
  /// In en, this message translates to:
  /// **'Blocking unfollows this user and hides their posts from you.'**
  String get communityBlockAuthorHint;

  /// No description provided for @communityBlockAuthorMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get communityBlockAuthorMenuSubtitle;

  /// No description provided for @communityReportPostMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This post'**
  String get communityReportPostMenuSubtitle;

  /// No description provided for @communityBlockAuthorShort.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get communityBlockAuthorShort;

  /// No description provided for @communityReportPostShort.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get communityReportPostShort;

  /// No description provided for @communityReportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this post?'**
  String get communityReportDialogTitle;

  /// No description provided for @communityReportReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get communityReportReasonHint;

  /// No description provided for @communityReportSend.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get communityReportSend;

  /// No description provided for @communityReportSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get communityReportSheetTitle;

  /// No description provided for @communityReportSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a reason for your report.'**
  String get communityReportSheetSubtitle;

  /// No description provided for @communityReportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or ads'**
  String get communityReportReasonSpam;

  /// No description provided for @communityReportReasonAbuse.
  ///
  /// In en, this message translates to:
  /// **'Harassment or hate'**
  String get communityReportReasonAbuse;

  /// No description provided for @communityReportReasonSexual.
  ///
  /// In en, this message translates to:
  /// **'Sexual content'**
  String get communityReportReasonSexual;

  /// No description provided for @communityReportReasonViolence.
  ///
  /// In en, this message translates to:
  /// **'Violence or threats'**
  String get communityReportReasonViolence;

  /// No description provided for @communityReportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get communityReportReasonOther;

  /// No description provided for @communityReportDetailHint.
  ///
  /// In en, this message translates to:
  /// **'Add details (optional)'**
  String get communityReportDetailHint;

  /// No description provided for @communityReportSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get communityReportSubmitButton;

  /// No description provided for @communityReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thanks — your report was submitted.'**
  String get communityReportSubmitted;

  /// No description provided for @communityBlockAuthorTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this user?'**
  String get communityBlockAuthorTitle;

  /// No description provided for @communityBlockAuthorMessage.
  ///
  /// In en, this message translates to:
  /// **'You will no longer see posts or this profile from {authorName}.'**
  String communityBlockAuthorMessage(String authorName);

  /// No description provided for @communityUserBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get communityUserBlocked;

  /// No description provided for @communityLikeLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in to like.'**
  String get communityLikeLogin;

  /// No description provided for @communityLikeCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String communityLikeCount(int count);

  /// No description provided for @communityCommentCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String communityCommentCount(int count);

  /// No description provided for @communityPostDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get communityPostDetailTitle;

  /// No description provided for @communityCommentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get communityCommentsTitle;

  /// No description provided for @communityWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get communityWrite;

  /// No description provided for @communityComposeTitle.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get communityComposeTitle;

  /// No description provided for @communityComposeSubmit.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get communityComposeSubmit;

  /// No description provided for @communityComposeOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get communityComposeOptionalTitle;

  /// No description provided for @communityComposeTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Add a title or leave blank'**
  String get communityComposeTitleHint;

  /// No description provided for @communityComposeSymbolLabel.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get communityComposeSymbolLabel;

  /// No description provided for @communityComposeThemePickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get communityComposeThemePickerLabel;

  /// No description provided for @communityComposePickTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose a theme'**
  String get communityComposePickTheme;

  /// No description provided for @communityComposeSymbolHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. TSLA, IBRX'**
  String get communityComposeSymbolHint;

  /// No description provided for @communityComposeAssetClassLabel.
  ///
  /// In en, this message translates to:
  /// **'Asset type'**
  String get communityComposeAssetClassLabel;

  /// No description provided for @communityComposeBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get communityComposeBodyLabel;

  /// No description provided for @communityComposeBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Spam, ads, harassment, or abuse may be removed; repeated violations may restrict your account. Please keep discussion respectful.'**
  String get communityComposeBodyHint;

  /// No description provided for @communityComposePhotosLabel.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get communityComposePhotosLabel;

  /// No description provided for @communityComposeNeedSymbol.
  ///
  /// In en, this message translates to:
  /// **'Choose a symbol.'**
  String get communityComposeNeedSymbol;

  /// No description provided for @communityComposeNeedBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the body text.'**
  String get communityComposeNeedBody;

  /// No description provided for @communityComposePickSymbol.
  ///
  /// In en, this message translates to:
  /// **'Choose symbol'**
  String get communityComposePickSymbol;

  /// No description provided for @communityComposeNoRankedSymbols.
  ///
  /// In en, this message translates to:
  /// **'No ranked symbols for this asset type. Open Home to load rankings and try again.'**
  String get communityComposeNoRankedSymbols;

  /// No description provided for @communityComposeAddPhotoShort.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get communityComposeAddPhotoShort;

  /// No description provided for @communityComposeAddGifShort.
  ///
  /// In en, this message translates to:
  /// **'GIF'**
  String get communityComposeAddGifShort;

  /// No description provided for @communityComposeGiphySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search GIPHY'**
  String get communityComposeGiphySearchHint;

  /// No description provided for @communityComposeGiphyPoweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by GIPHY'**
  String get communityComposeGiphyPoweredBy;

  /// No description provided for @communityComposeGiphyTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is over 5MB. Pick another GIF.'**
  String get communityComposeGiphyTooLarge;

  /// No description provided for @communityComposeGiphyDownloadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the GIF. Try again.'**
  String get communityComposeGiphyDownloadError;

  /// No description provided for @communityComposeGiphyRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a moment. (rate limit)'**
  String get communityComposeGiphyRateLimited;

  /// No description provided for @communityComposeGiphyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the list.'**
  String get communityComposeGiphyLoadError;

  /// No description provided for @communityComposeGiphyRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get communityComposeGiphyRetry;

  /// No description provided for @communityComposeGiphyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No results.'**
  String get communityComposeGiphyEmpty;

  /// No description provided for @communityComposeGiphyThumbError.
  ///
  /// In en, this message translates to:
  /// **'Preview unavailable'**
  String get communityComposeGiphyThumbError;

  /// No description provided for @communityComposeEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get communityComposeEditTitle;

  /// No description provided for @communityComposeSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get communityComposeSave;

  /// No description provided for @communityComposeEditReplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit reply'**
  String get communityComposeEditReplyTitle;

  /// No description provided for @ugcBannedWordsMessage.
  ///
  /// In en, this message translates to:
  /// **'This text contains disallowed wording: {term}'**
  String ugcBannedWordsMessage(String term);

  /// No description provided for @navRankings.
  ///
  /// In en, this message translates to:
  /// **'Rankings'**
  String get navRankings;

  /// No description provided for @navThemes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get navThemes;

  /// No description provided for @navMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get navMarket;

  /// No description provided for @homeRankingApplyFiltersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Apply selected filters to rankings'**
  String get homeRankingApplyFiltersTooltip;

  /// No description provided for @rankingsUpTab.
  ///
  /// In en, this message translates to:
  /// **'Surging 🔥'**
  String get rankingsUpTab;

  /// No description provided for @rankingsDownTab.
  ///
  /// In en, this message translates to:
  /// **'Crashing 💀'**
  String get rankingsDownTab;

  /// No description provided for @rankingsUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Wildest gainers today'**
  String get rankingsUpTitle;

  /// No description provided for @rankingsDownTitle.
  ///
  /// In en, this message translates to:
  /// **'Biggest losers today'**
  String get rankingsDownTitle;

  /// No description provided for @homeRankingsShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share rankings'**
  String get homeRankingsShareTooltip;

  /// No description provided for @homeRankingsShareEmptySnack.
  ///
  /// In en, this message translates to:
  /// **'No rankings to share yet.'**
  String get homeRankingsShareEmptySnack;

  /// No description provided for @homeRankingsShareFiltersLine.
  ///
  /// In en, this message translates to:
  /// **'Filters: {filters}'**
  String homeRankingsShareFiltersLine(String filters);

  /// No description provided for @homeInterestSurgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s interest surge'**
  String get homeInterestSurgeTitle;

  /// No description provided for @homeInterestSurgeInfoIconTooltip.
  ///
  /// In en, this message translates to:
  /// **'How this list is built'**
  String get homeInterestSurgeInfoIconTooltip;

  /// No description provided for @homeInterestSurgeInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'About today\'s interest surge'**
  String get homeInterestSurgeInfoTitle;

  /// No description provided for @homeInterestSurgeInfoBody.
  ///
  /// In en, this message translates to:
  /// **'This list is built with AI: it picks US and Korean stocks, crypto, and commodities that look attention-worthy from recent market context, news, and investor-interest signals, then estimates a relative 0–100 \"trend\" score for each.\n\nScores are processed and stored on our servers once per day; the app shows the latest snapshot.\n\nFor information only—not investment advice, and not a guarantee of returns.'**
  String get homeInterestSurgeInfoBody;

  /// No description provided for @homeInterestSurgeInfoDismiss.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get homeInterestSurgeInfoDismiss;

  /// No description provided for @homeTrendScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get homeTrendScoreLabel;

  /// No description provided for @homeRankingShowMoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get homeRankingShowMoreTooltip;

  /// No description provided for @homeInterestSurgeShowMoreWithAd.
  ///
  /// In en, this message translates to:
  /// **'Watch ad to show more'**
  String get homeInterestSurgeShowMoreWithAd;

  /// No description provided for @homeRankingShowLessTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get homeRankingShowLessTooltip;

  /// No description provided for @themesHotTitle.
  ///
  /// In en, this message translates to:
  /// **'Hottest themes today'**
  String get themesHotTitle;

  /// No description provided for @themesCrashedTitle.
  ///
  /// In en, this message translates to:
  /// **'Themes that got crushed'**
  String get themesCrashedTitle;

  /// No description provided for @themesEmergingTitle.
  ///
  /// In en, this message translates to:
  /// **'Suddenly trending themes'**
  String get themesEmergingTitle;

  /// No description provided for @marketSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Market summary'**
  String get marketSummaryTitle;

  /// No description provided for @kimchiPremiumLabel.
  ///
  /// In en, this message translates to:
  /// **'Kimchi premium'**
  String get kimchiPremiumLabel;

  /// No description provided for @exchangeRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate'**
  String get exchangeRateLabel;

  /// No description provided for @marketStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Market mood'**
  String get marketStatusLabel;

  /// No description provided for @dopamineScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Dopamine score'**
  String get dopamineScoreLabel;

  /// No description provided for @errorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load data.'**
  String get errorLoadFailed;

  /// No description provided for @errorNoApi.
  ///
  /// In en, this message translates to:
  /// **'API base URL is not set. Pass --dart-define=API_BASE_URL=... when running.'**
  String get errorNoApi;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @emptyState.
  ///
  /// In en, this message translates to:
  /// **'No data to show.'**
  String get emptyState;

  /// No description provided for @assetName.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get assetName;

  /// No description provided for @priceChangePct.
  ///
  /// In en, this message translates to:
  /// **'Price change'**
  String get priceChangePct;

  /// No description provided for @volumeChangePct.
  ///
  /// In en, this message translates to:
  /// **'Volume change'**
  String get volumeChangePct;

  /// No description provided for @summaryLine.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryLine;

  /// No description provided for @themeName.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeName;

  /// No description provided for @themeScore.
  ///
  /// In en, this message translates to:
  /// **'Theme score'**
  String get themeScore;

  /// No description provided for @stockCount.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get stockCount;

  /// No description provided for @sectionRankings.
  ///
  /// In en, this message translates to:
  /// **'Up · Down'**
  String get sectionRankings;

  /// No description provided for @sectionThemes.
  ///
  /// In en, this message translates to:
  /// **'Theme rankings'**
  String get sectionThemes;

  /// No description provided for @sectionMarket.
  ///
  /// In en, this message translates to:
  /// **'Market summary'**
  String get sectionMarket;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @homeTopSurgeBadge.
  ///
  /// In en, this message translates to:
  /// **'TOP 10'**
  String get homeTopSurgeBadge;

  /// No description provided for @homeKicker.
  ///
  /// In en, this message translates to:
  /// **'Only what moves. Where money flows right now.'**
  String get homeKicker;

  /// No description provided for @homeLiveBadge.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get homeLiveBadge;

  /// No description provided for @homeThemeStockLine.
  ///
  /// In en, this message translates to:
  /// **'{count} stocks'**
  String homeThemeStockLine(int count);

  /// No description provided for @assetClassBadgeUsStock.
  ///
  /// In en, this message translates to:
  /// **'US stock'**
  String get assetClassBadgeUsStock;

  /// No description provided for @assetClassBadgeKrStock.
  ///
  /// In en, this message translates to:
  /// **'Korea'**
  String get assetClassBadgeKrStock;

  /// No description provided for @assetClassBadgeJpStock.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get assetClassBadgeJpStock;

  /// No description provided for @assetClassBadgeCnStock.
  ///
  /// In en, this message translates to:
  /// **'China'**
  String get assetClassBadgeCnStock;

  /// No description provided for @assetClassJpStock.
  ///
  /// In en, this message translates to:
  /// **'Japan stocks'**
  String get assetClassJpStock;

  /// No description provided for @assetClassCnStock.
  ///
  /// In en, this message translates to:
  /// **'China A-shares'**
  String get assetClassCnStock;

  /// No description provided for @assetClassBadgeCrypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get assetClassBadgeCrypto;

  /// No description provided for @assetClassBadgeCommodity.
  ///
  /// In en, this message translates to:
  /// **'Commodity'**
  String get assetClassBadgeCommodity;

  /// No description provided for @assetClassBadgeTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get assetClassBadgeTheme;

  /// No description provided for @communityComposeThemeNameHint.
  ///
  /// In en, this message translates to:
  /// **'Theme name (e.g. Energy & commodities)'**
  String get communityComposeThemeNameHint;

  /// No description provided for @rankingFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Asset classes'**
  String get rankingFilterTitle;

  /// No description provided for @rankingFilterConfirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get rankingFilterConfirm;

  /// No description provided for @rankingFilterCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get rankingFilterCancel;

  /// No description provided for @rankingFilterNeedOne.
  ///
  /// In en, this message translates to:
  /// **'Select at least one.'**
  String get rankingFilterNeedOne;

  /// No description provided for @assetDetailMissingClass.
  ///
  /// In en, this message translates to:
  /// **'Missing asset class for this item.'**
  String get assetDetailMissingClass;

  /// No description provided for @assetDetailSectionProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get assetDetailSectionProfile;

  /// No description provided for @assetDetailMarketCap.
  ///
  /// In en, this message translates to:
  /// **'Market cap'**
  String get assetDetailMarketCap;

  /// No description provided for @assetDetailMarketCapKrwMillions.
  ///
  /// In en, this message translates to:
  /// **'{amount}M KRW'**
  String assetDetailMarketCapKrwMillions(String amount);

  /// No description provided for @assetDetailMarketCapKrwWonFull.
  ///
  /// In en, this message translates to:
  /// **'{amount} KRW'**
  String assetDetailMarketCapKrwWonFull(String amount);

  /// No description provided for @assetDetailMarketCapRank.
  ///
  /// In en, this message translates to:
  /// **'Market cap rank'**
  String get assetDetailMarketCapRank;

  /// No description provided for @assetDetailCurrentPrice.
  ///
  /// In en, this message translates to:
  /// **'Price (USD)'**
  String get assetDetailCurrentPrice;

  /// No description provided for @assetDetailCryptoProfileMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get assetDetailCryptoProfileMore;

  /// No description provided for @assetDetailCryptoProfileLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get assetDetailCryptoProfileLess;

  /// No description provided for @assetDetailSector.
  ///
  /// In en, this message translates to:
  /// **'Sector'**
  String get assetDetailSector;

  /// No description provided for @assetDetailIndustry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get assetDetailIndustry;

  /// No description provided for @assetDetailExchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get assetDetailExchange;

  /// No description provided for @assetDetailCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get assetDetailCurrency;

  /// No description provided for @assetDetailPair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get assetDetailPair;

  /// No description provided for @assetDetailAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get assetDetailAbout;

  /// No description provided for @assetDetailWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get assetDetailWebsite;

  /// No description provided for @assetDetailNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get assetDetailNotAvailable;

  /// No description provided for @assetDetailOpenLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open link.'**
  String get assetDetailOpenLinkFailed;

  /// No description provided for @assetDetailPriceChange.
  ///
  /// In en, this message translates to:
  /// **'Price change (feed)'**
  String get assetDetailPriceChange;

  /// No description provided for @communitySortLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get communitySortLatest;

  /// No description provided for @communitySortPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get communitySortPopular;

  /// No description provided for @communityReplyCount.
  ///
  /// In en, this message translates to:
  /// **'Replies: {count}'**
  String communityReplyCount(int count);

  /// No description provided for @assetPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent reactions'**
  String get assetPostsTitle;

  /// No description provided for @assetPostsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Be the first to post.'**
  String get assetPostsEmpty;

  /// No description provided for @assetPostsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Leave a comment.'**
  String get assetPostsPlaceholder;

  /// No description provided for @assetPostsReplyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write a reply.'**
  String get assetPostsReplyPlaceholder;

  /// No description provided for @assetPostsPublish.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get assetPostsPublish;

  /// No description provided for @assetPostsReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get assetPostsReply;

  /// No description provided for @assetPostsReplying.
  ///
  /// In en, this message translates to:
  /// **'Replying'**
  String get assetPostsReplying;

  /// No description provided for @assetPostsCancelReply.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get assetPostsCancelReply;

  /// No description provided for @assetPostsSendError.
  ///
  /// In en, this message translates to:
  /// **'Could not publish your post.'**
  String get assetPostsSendError;

  /// No description provided for @assetDetailMoveSummary.
  ///
  /// In en, this message translates to:
  /// **'Today’s move (AI)'**
  String get assetDetailMoveSummary;

  /// No description provided for @assetDetailMoveSummaryDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI-generated from public figures only—not investment advice.'**
  String get assetDetailMoveSummaryDisclaimer;

  /// No description provided for @assetDetailNewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Headlines'**
  String get assetDetailNewsTitle;

  /// No description provided for @assetDetailNewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent headlines for this search.'**
  String get assetDetailNewsEmpty;

  /// No description provided for @assetDetailNewsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load headlines. Check your connection or try again.'**
  String get assetDetailNewsError;

  /// No description provided for @assetDetailNewsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Headlines from third-party sources—titles and links only.'**
  String get assetDetailNewsDisclaimer;

  /// No description provided for @assetDetailNewsShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get assetDetailNewsShowMore;

  /// No description provided for @assetDetailNewsShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get assetDetailNewsShowLess;

  /// No description provided for @assetDetailNewsWatchAdAiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Watch ad · AI news analysis'**
  String get assetDetailNewsWatchAdAiAnalysis;

  /// No description provided for @assetDetailOpenCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get assetDetailOpenCommunity;

  /// No description provided for @communitySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search words in posts (OR)…'**
  String get communitySearchHint;

  /// No description provided for @assetDetailOpenChart.
  ///
  /// In en, this message translates to:
  /// **'View chart'**
  String get assetDetailOpenChart;

  /// No description provided for @assetDetailOpenInToss.
  ///
  /// In en, this message translates to:
  /// **'Toss'**
  String get assetDetailOpenInToss;

  /// No description provided for @assetDetailOpenInTossTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open order screen in Toss Securities'**
  String get assetDetailOpenInTossTooltip;

  /// No description provided for @assetDetailOpenInExchange.
  ///
  /// In en, this message translates to:
  /// **'View on {exchange}'**
  String assetDetailOpenInExchange(String exchange);

  /// No description provided for @assetChartRange1mo.
  ///
  /// In en, this message translates to:
  /// **'1M'**
  String get assetChartRange1mo;

  /// No description provided for @assetChartRange3mo.
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get assetChartRange3mo;

  /// No description provided for @assetChartRange1y.
  ///
  /// In en, this message translates to:
  /// **'1Y'**
  String get assetChartRange1y;

  /// No description provided for @assetChartFootnote.
  ///
  /// In en, this message translates to:
  /// **'Daily candles via Yahoo (server). Not investment advice.'**
  String get assetChartFootnote;

  /// No description provided for @themeDetailChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme average (normalized)'**
  String get themeDetailChartTitle;

  /// No description provided for @themeDetailChartFootnote.
  ///
  /// In en, this message translates to:
  /// **'Synthetic index: each symbol rebased to 100 at its first bar in the range, then averaged by calendar day. Yahoo daily via server. Not investment advice.'**
  String get themeDetailChartFootnote;

  /// No description provided for @accountSuspendedBanner.
  ///
  /// In en, this message translates to:
  /// **'Your account cannot post, edit, delete, or reply in the community right now.'**
  String get accountSuspendedBanner;

  /// No description provided for @accountSuspendedSnack.
  ///
  /// In en, this message translates to:
  /// **'This account is restricted from community activity.'**
  String get accountSuspendedSnack;

  /// No description provided for @shareSheetKakaoTalk.
  ///
  /// In en, this message translates to:
  /// **'Share to KakaoTalk'**
  String get shareSheetKakaoTalk;

  /// No description provided for @shareSheetSystemShare.
  ///
  /// In en, this message translates to:
  /// **'System share'**
  String get shareSheetSystemShare;

  /// No description provided for @shareSheetCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get shareSheetCopyLink;

  /// No description provided for @shareSheetCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get shareSheetCopied;
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
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
