// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ドーパミン資産';

  @override
  String get homeHeaderTitleDecorated => 'ドーパミン資産';

  @override
  String get navHome => 'ホーム';

  @override
  String get actionLogin => 'ログイン';

  @override
  String get navCommunity => 'コミュニティ';

  @override
  String get navFavorites => 'ウォッチリスト';

  @override
  String get favoritesEmpty => 'お気に入りはまだ保存されていません。';

  @override
  String get favoritesSignInToSave => 'このデバイスでお気に入りを保存して表示するにはサインインしてください。';

  @override
  String get navProfile => '材料形状';

  @override
  String get profileSignedInSection => 'アカウント';

  @override
  String get profileAccountRefreshTooltip => 'プロフィールとアクティビティを更新する';

  @override
  String get profileDisplayName => '表示名';

  @override
  String get profilePhotoTitle => 'プロフィール写真';

  @override
  String get profilePhotoRemove => '写真を削除';

  @override
  String get profilePhotoSaved => 'プロフィール写真を保存しました。';

  @override
  String get profilePhotoRemoved => 'プロフィール写真を削除しました。';

  @override
  String get profileEmail => 'メール';

  @override
  String get profileUid => 'ユーザーID';

  @override
  String get profileNoEmail => '設定されていません（ソーシャルログイン）';

  @override
  String get profileLogout => 'ログアウト';

  @override
  String get profileLogoutDone => 'ログアウトしました';

  @override
  String get profileDeleteAccount => '口座を削除';

  @override
  String get profileDeleteTitle => '口座を削除';

  @override
  String get profileDeleteMessage => 'これは元に戻せません。Firebaseアカウントとサインインは削除されます。';

  @override
  String get profileDeleteCancel => '取り消す';

  @override
  String get profileDeleteConfirm => '削除';

  @override
  String get profileDeleteDone => 'アカウントを削除しました';

  @override
  String get profileRequiresRecentLogin => 'もう一度サインインして、もう一度お試しください（セキュリティ）。';

  @override
  String get profileNotSignedIn => 'あなたのアカウントにサインイン';

  @override
  String get profileSaveDisplayName => '保存';

  @override
  String get profileDisplayNameHint => '投稿に名前が表示される仕組み';

  @override
  String get profileDisplayNameInputPlaceholder => '表示名を入力';

  @override
  String get profileCheckDisplayNameDuplicate => '空室状況を確認する';

  @override
  String get profileDisplayNameEmpty => '表示名を入力してください。';

  @override
  String get profileDisplayNameCheckFirst => '保存する前に予約可能状況をご確認ください。';

  @override
  String get profileNicknameRequiredForCommunity => 'プロフィールで表示名を設定します。';

  @override
  String get profilePushTitle => 'プッシュ通知';

  @override
  String get profileSettingsTitle => '設定';

  @override
  String get profileSettingsLegalDisclosures => 'データソースと免責事項';

  @override
  String get profilePushMaster => 'すべての通知';

  @override
  String get profilePushSocialReply => '投稿/コメントへの返信';

  @override
  String get profilePushSocialLike => 'コメントへの「いいね」';

  @override
  String get profilePushMarketDaily => 'デイリーマーケットサマリー';

  @override
  String get profilePushHotMoverDiscussion => 'ホット・ムーバー—活発なディスカッション';

  @override
  String get profileStatPosts => '投稿';

  @override
  String get profileStatFollowing => 'フォロー中';

  @override
  String get profileStatFollowers => 'フォロワー';

  @override
  String get profileStatBlocked => 'ブロック済';

  @override
  String get profileBlockedTitle => 'ブロック中のユーザー';

  @override
  String get profileBlockedListEmpty => '誰もブロックしていません。';

  @override
  String get profileUnblockAction => 'ブロック解除';

  @override
  String get profileUnblockedDone => '解除済み';

  @override
  String get profileActivityTitle => 'Activity - アクティビティ';

  @override
  String get profileActivityMyPost => 'あなたの投稿';

  @override
  String profileActivityPostOnAsset(String assetName) {
    return '$assetNameに投稿';
  }

  @override
  String get profileActivityMyReply => 'あなたの返信';

  @override
  String get profileActivityReplyOnPost => '投稿に返信する';

  @override
  String get profileActivityLikeReceived => 'あなたのコメントにいいねする';

  @override
  String get profileActivityLikeGiven => 'コメントにいいねしました';

  @override
  String get profileActivityEditPost => '編集';

  @override
  String get profileActivityDeletePost => '削除';

  @override
  String get profileActivityEditDialogTitle => '投稿の編集';

  @override
  String get profileActivityDeleteDialogTitle => '投稿を削除';

  @override
  String get profileActivityPostDeleted => '削除しました。';

  @override
  String get profileActivityPostUpdated => '保存しました。';

  @override
  String get profileFollowListEmpty => 'ユーザーはまだいません';

  @override
  String get profileDisplayNameSaved => '表示名が更新されました。';

  @override
  String get profileDisplayNameTaken => 'この表示名は既に使用されています。';

  @override
  String get profileDisplayNameDuplicateFromSocialTitle => '表示名';

  @override
  String profileDisplayNameDuplicateFromSocialMessage(String name) {
    return 'サインインプロバイダの名前「$name」はすでに使用されています。下に新しい名前を入力し、「予約可能状況を確認」、「保存」の順にタップ';
  }

  @override
  String get profileDisplayNameDuplicateFromSocialOk => 'OK';

  @override
  String get privacyProcessingConsentTitle => '利用規約、コミュニティ、プライバシー';

  @override
  String get privacyProcessingConsentLead =>
      'コミュニティやその他のユーザー生成コンテンツを含むサービスを使用するには、続行する前に以下をお読みになり、同意してください。';

  @override
  String get privacyProcessingConsentSectionPrivacy => '個人データ';

  @override
  String get privacyProcessingConsentSectionCommunity =>
      'コミュニティ＆ユーザー生成コンテンツ（ UGC ）';

  @override
  String get privacyProcessingConsentUgcIntro =>
      '投稿、コメント、その他のUGCにアクセスする前に、次のルールが適用されます。';

  @override
  String get privacyProcessingConsentBullet1 =>
      '収集されたデータ：アカウント識別子（ Firebase UID ）、提供された場合は電子メール、表示名とプロフィール写真、および投稿、コメント、ウォッチリストなどの使用を通じて生成された情報。';

  @override
  String get privacyProcessingConsentBullet2 =>
      '目的：識別、コミュニティとフィードの機能、サポート、不正使用の防止、サービスの改善。';

  @override
  String get privacyProcessingConsentBullet3 =>
      '保持：お客様がアカウントを削除すると、当社はデータを削除または匿名化します。ただし、法律でより長期の保持が義務付けられている場合を除きます。';

  @override
  String get privacyProcessingConsentUgcBullet1 =>
      'ゼロトレランス：不快なコンテンツは許可されていません。これには、違法なコンテンツ、ハラスメント、憎悪、同意のない性的コンテンツ、暴力、脅迫、スパム、詐欺、および同様の虐待が含まれます。';

  @override
  String get privacyProcessingConsentUgcBullet2 =>
      '虐待的なユーザーは容認されません。当社は、これらの規則に違反するコンテンツの削除、機能の制限、アカウントの一時停止または終了を行う場合があります。';

  @override
  String get privacyProcessingConsentUgcBullet3 =>
      '不快な投稿を報告したり、投稿やプロフィールのメニューからユーザーをブロックしたりすることができます。有害なコンテンツや行動を見つけた場合は、レポートを使用してブロックしてください。';

  @override
  String get privacyProcessingConsentCheckboxPrivacy =>
      '私は、上記の個人データセクションに記載されているように、私の個人データの収集と使用に同意します。';

  @override
  String get privacyProcessingConsentCheckboxCommunity =>
      '私は、不快なコンテンツや虐待的なユーザーに対するゼロトレランスを含む、上記のコミュニティとUGCの規則に同意します。';

  @override
  String get privacyProcessingConsentAgree => '同意して続行';

  @override
  String get privacyProcessingConsentDecline => '拒否する';

  @override
  String get profileFollowUnfollow => 'フォロー解除';

  @override
  String get profileFollowTitleFollowing => 'フォロー中';

  @override
  String get profileFollowTitleFollowers => 'フォロワー';

  @override
  String get communityFollow => 'フォロー';

  @override
  String get communityUnfollow => 'フォロー解除';

  @override
  String get communityOpenAssetDetail => 'アセットの詳細';

  @override
  String get communityMoreMenu => '増加';

  @override
  String get communityPostSeeMore => 'もっと見る';

  @override
  String get communityShowOriginal => '原文を表示';

  @override
  String get communityShowTranslated => '翻訳を表示';

  @override
  String get communityReportPost => 'レポート';

  @override
  String get communityBlockAuthor => 'ユーザーをブロック';

  @override
  String get communityPostHiddenByReportNotice =>
      'レポートを確認した後、この投稿は他のユーザーには非表示になっています。';

  @override
  String get communityBlockAuthorHint =>
      'ブロックすると、このユーザーのフォローが解除され、投稿が非表示になります。';

  @override
  String get communityBlockAuthorMenuSubtitle => 'ユーザー';

  @override
  String get communityReportPostMenuSubtitle => 'この投稿';

  @override
  String get communityBlockAuthorShort => 'ブロック';

  @override
  String get communityReportPostShort => 'レポート';

  @override
  String get communityReportDialogTitle => 'この投稿を報告';

  @override
  String get communityReportReasonHint => '理由 (オプション)';

  @override
  String get communityReportSend => 'レポート';

  @override
  String get communityReportSheetTitle => 'レポート';

  @override
  String get communityReportSheetSubtitle => 'レポートの理由を選択してください。';

  @override
  String get communityReportReasonSpam => 'スパムまたは広告';

  @override
  String get communityReportReasonAbuse => 'ハラスメントまたは憎悪';

  @override
  String get communityReportReasonSexual => '性的なコンテンツ';

  @override
  String get communityReportReasonViolence => '暴力または脅迫';

  @override
  String get communityReportReasonOther => 'その他';

  @override
  String get communityReportDetailHint => 'その他の詳細（オプション）';

  @override
  String get communityReportSubmitButton => 'レポートを送信';

  @override
  String get communityReportSubmitted => 'ありがとうございます。レポートが送信されました。';

  @override
  String get communityBlockAuthorTitle => 'このユーザーをブロック';

  @override
  String communityBlockAuthorMessage(String authorName) {
    return '$authorName以降の投稿やこのプロフィールは表示されなくなります。';
  }

  @override
  String get communityUserBlocked => 'ユーザーがブロックされました';

  @override
  String get communityLikeLogin => 'いいねするにはサインインしてください。';

  @override
  String communityLikeCount(int count) {
    return '$count';
  }

  @override
  String communityCommentCount(int count) {
    return '$count';
  }

  @override
  String get communityPostDetailTitle => '役職';

  @override
  String get communityCommentsTitle => 'コメント';

  @override
  String get communityWrite => '書き込み';

  @override
  String get communityComposeTitle => '新しい投稿';

  @override
  String get communityComposeSubmit => '役職';

  @override
  String get communityComposeOptionalTitle => 'タイトル （オプション）';

  @override
  String get communityComposeTitleHint => 'タイトルを追加するか、空白のままにしてください';

  @override
  String get communityComposeSymbolLabel => '記号';

  @override
  String get communityComposeThemePickerLabel => 'テーマ';

  @override
  String get communityComposePickTheme => 'テーマを選択してください';

  @override
  String get communityComposeSymbolHint => '例： TSLA、IBRX';

  @override
  String get communityComposeAssetClassLabel => '資産種類';

  @override
  String get communityComposeBodyLabel => 'ボディ';

  @override
  String get communityComposeBodyHint =>
      'スパム、広告、ハラスメント、または悪用は削除される可能性があります。繰り返しの違反により、アカウントが制限される可能性があります。ディスカッションは敬意を持って行ってください。';

  @override
  String get communityComposePhotosLabel => '写真';

  @override
  String get communityComposeNeedSymbol => 'シンボルを選択';

  @override
  String get communityComposeNeedBody => '本文テキストを入力します。';

  @override
  String get communityComposePickSymbol => 'シンボルを選択';

  @override
  String get communityComposeNoRankedSymbols =>
      'このアセットタイプのランク付けされたシンボルはありません。ホームを開いてランキングを読み込み、もう一度お試しください。';

  @override
  String get communityComposeAddPhotoShort => '写真';

  @override
  String get communityComposeAddGifShort => 'GIF';

  @override
  String get communityComposeGiphySearchHint => 'Giphyを検索';

  @override
  String get communityComposeGiphyPoweredBy => 'Powered by GIPHY';

  @override
  String get communityComposeGiphyTooLarge =>
      'このファイルは5 MBを超えています。別のGIFを選択してください。';

  @override
  String get communityComposeGiphyDownloadError =>
      'GIFを読み込めませんでした。もう一度やり直してください。';

  @override
  String get communityComposeGiphyRateLimited => 'しばらくしてからもう一度お試しください。（レート制限）';

  @override
  String get communityComposeGiphyLoadError => 'リストを読み込めませんでした。';

  @override
  String get communityComposeGiphyRetry => '再試行';

  @override
  String get communityComposeGiphyEmpty => '結果がありません。';

  @override
  String get communityComposeGiphyThumbError => 'プレビューは利用できません';

  @override
  String get communityComposeEditTitle => '投稿の編集';

  @override
  String get communityComposeSave => '保存';

  @override
  String get communityComposeEditReplyTitle => '返事を編集する';

  @override
  String ugcBannedWordsMessage(String term) {
    return 'このテキストには、許可されていない文言が含まれています。$term';
  }

  @override
  String get navRankings => 'ランキング';

  @override
  String get navThemes => 'テーマ';

  @override
  String get navMarket => 'Market';

  @override
  String get homeRankingApplyFiltersTooltip => '選択したフィルターをランキングに適用';

  @override
  String get rankingsUpTab => 'サージング 🔥';

  @override
  String get rankingsDownTab => 'クラッシュしている';

  @override
  String get rankingsUpTitle => '今日最もワイルドな獲得者';

  @override
  String get rankingsDownTitle => '今日の最大の敗者';

  @override
  String get homeRankingsShareTooltip => 'ランキングをシェアする';

  @override
  String get homeRankingsShareEmptySnack => '共有できるランキングはまだありません。';

  @override
  String homeRankingsShareFiltersLine(String filters) {
    return 'フィルター： $filters';
  }

  @override
  String get homeInterestSurgeTitle => '本日の金利の急騰';

  @override
  String get homeInterestSurgeInfoIconTooltip => 'このリストの作成方法';

  @override
  String get homeInterestSurgeInfoTitle => '本日の金利上昇について';

  @override
  String get homeInterestSurgeInfoBody =>
      'このリストはAIを使用して作成されています。最近の市場状況、ニュース、投資家の利益シグナルから注目に値すると思われる米国と韓国の株式、暗号通貨、および商品を選択し、それぞれの相対的な0〜100の「トレンド」スコアを推定します。\n\nスコアは1日に1回処理され、サーバーに保存されます。アプリには最新のスナップショットが表示されます。\n\n情報のみ-投資アドバイスではなく、リターンの保証ではありません。';

  @override
  String get homeInterestSurgeInfoDismiss => 'OK';

  @override
  String get homeTrendScoreLabel => 'トレンド';

  @override
  String get homeRankingShowMoreTooltip => 'もっと表示';

  @override
  String get homeInterestSurgeShowMoreWithAd => '広告を視聴して詳細を表示';

  @override
  String get homeRankingShowLessTooltip => '簡易表示';

  @override
  String get themesHotTitle => '今日の最も人気のあるテーマ';

  @override
  String get themesCrashedTitle => '潰されたテーマ';

  @override
  String get themesEmergingTitle => '急上昇中のトレンドテーマ';

  @override
  String get marketSummaryTitle => '市場の概要';

  @override
  String get kimchiPremiumLabel => 'キムチプレミアム';

  @override
  String get exchangeRateLabel => '換金率';

  @override
  String get marketStatusLabel => '市場の雰囲気';

  @override
  String get dopamineScoreLabel => 'ドーパミンスコア';

  @override
  String get errorLoadFailed => 'データを読み込めませんでした。';

  @override
  String get errorNoApi =>
      'APIベースURLが設定されていません。実行時に-- dart - define = API_BASE_URL =...を渡します。';

  @override
  String get retry => '再試行';

  @override
  String get loading => '読み込み中...';

  @override
  String get emptyState => '表示するデータがありません';

  @override
  String get assetName => 'アセット';

  @override
  String get priceChangePct => '価格の変更';

  @override
  String get volumeChangePct => '音量変化';

  @override
  String get summaryLine => '要約';

  @override
  String get themeName => 'テーマ';

  @override
  String get themeScore => 'テーマスコア';

  @override
  String get stockCount => 'シンボル';

  @override
  String get sectionRankings => '上・下';

  @override
  String get sectionThemes => 'テーマランキング';

  @override
  String get sectionMarket => '市場の概要';

  @override
  String get notAvailable => 'N/A';

  @override
  String get homeTopSurgeBadge => 'トップ10';

  @override
  String get homeKicker => '動くものだけ。今お金が流れる場所。';

  @override
  String get homeLiveBadge => 'ライブ';

  @override
  String homeThemeStockLine(int count) {
    return '$count在庫';
  }

  @override
  String get assetClassBadgeUsStock => '米国株';

  @override
  String get assetClassBadgeKrStock => '韓国株';

  @override
  String get assetClassBadgeJpStock => '日本株';

  @override
  String get assetClassBadgeCnStock => '中国株';

  @override
  String get assetClassJpStock => '日本株';

  @override
  String get assetClassCnStock => '中国A株';

  @override
  String get assetClassBadgeCrypto => '暗号通貨';

  @override
  String get assetClassBadgeCommodity => '商品';

  @override
  String get assetClassBadgeTheme => 'テーマ';

  @override
  String get communityComposeThemeNameHint => 'テーマ名（例：エネルギー＆コモディティ）';

  @override
  String get rankingFilterTitle => 'アセットクラス';

  @override
  String get rankingFilterConfirm => 'OK';

  @override
  String get rankingFilterCancel => '取り消す';

  @override
  String get rankingFilterNeedOne => '少なくとも1日を選択してください。';

  @override
  String get assetDetailMissingClass => 'このアイテムの資産クラスがありません。';

  @override
  String get assetDetailSectionProfile => '材料形状';

  @override
  String get assetDetailMarketCap => '時価総額';

  @override
  String assetDetailMarketCapKrwMillions(String amount) {
    return '$amount百万ウォン';
  }

  @override
  String assetDetailMarketCapKrwWonFull(String amount) {
    return '$amountウォン';
  }

  @override
  String get assetDetailMarketCapRank => '時価総額';

  @override
  String get assetDetailCurrentPrice => '価格（米ドル）';

  @override
  String get assetDetailCryptoProfileMore => '増加';

  @override
  String get assetDetailCryptoProfileLess => '減少';

  @override
  String get assetDetailSector => 'セクター';

  @override
  String get assetDetailIndustry => '業種';

  @override
  String get assetDetailExchange => '取引所';

  @override
  String get assetDetailCurrency => '通貨';

  @override
  String get assetDetailPair => 'ペア';

  @override
  String get assetDetailAbout => '情報';

  @override
  String get assetDetailWebsite => 'Web サイト';

  @override
  String get assetDetailNotAvailable => '—';

  @override
  String get assetDetailOpenLinkFailed => 'リンクを開けませんでした。';

  @override
  String get assetDetailPriceChange => '価格変更（フィード）';

  @override
  String get communitySortLatest => '最新';

  @override
  String get communitySortPopular => '人気';

  @override
  String communityReplyCount(int count) {
    return '返信： $count';
  }

  @override
  String get assetPostsTitle => '最近の反応';

  @override
  String get assetPostsEmpty => '一番乗りで投稿しましょう。';

  @override
  String get assetPostsPlaceholder => 'コメントをどうぞ';

  @override
  String get assetPostsReplyPlaceholder => '返信する';

  @override
  String get assetPostsPublish => '役職';

  @override
  String get assetPostsReply => '返信する';

  @override
  String get assetPostsReplying => '返信中…';

  @override
  String get assetPostsCancelReply => '取り消す';

  @override
  String get assetPostsSendError => '投稿を公開できませんでした。';

  @override
  String get assetDetailMoveSummary => '本日のムーブ（ AI ）';

  @override
  String get assetDetailMoveSummaryDisclaimer =>
      'AIは公人のみから生成され、投資アドバイスではありません。';

  @override
  String get assetDetailNewsTitle => 'ヘッドライン';

  @override
  String get assetDetailNewsEmpty => 'この検索の最近の見出しはありません。';

  @override
  String get assetDetailNewsError => '見出しを読み込めませんでした。接続を確認するか、もう一度お試しください。';

  @override
  String get assetDetailNewsDisclaimer => 'サードパーティの情報源からの見出し-タイトルとリンクのみ。';

  @override
  String get assetDetailNewsShowMore => 'もっと表示';

  @override
  String get assetDetailNewsShowLess => '簡易表示';

  @override
  String get assetDetailNewsWatchAdAiAnalysis => '広告を見る・AIニュース解析';

  @override
  String get assetDetailOpenCommunity => 'コミュニティ';

  @override
  String get communitySearchHint => '投稿内の単語を検索（または） …';

  @override
  String get assetDetailOpenChart => 'チャートを表示する';

  @override
  String get assetChartRange1mo => '1ヶ月';

  @override
  String get assetChartRange3mo => '3ヶ月';

  @override
  String get assetChartRange1y => '1年';

  @override
  String get assetChartFootnote => 'Yahoo （サーバー）経由の毎日のキャンドル。投資アドバイスではありません。';

  @override
  String get themeDetailChartTitle => 'テーマ平均（正規化）';

  @override
  String get themeDetailChartFootnote =>
      '合成指数：各シンボルは、範囲内の最初のバーで100にリベースし、暦日で平均化されます。サーバー経由で毎日Yahoo。投資アドバイスではありません。';

  @override
  String get accountSuspendedBanner =>
      '現在、コミュニティ内でアカウントを投稿、編集、削除、返信することはできません。';

  @override
  String get accountSuspendedSnack => 'このアカウントはコミュニティ活動に制限されています。';

  @override
  String get shareSheetKakaoTalk => 'カカオトークで共有';

  @override
  String get shareSheetSystemShare => '共有';

  @override
  String get shareSheetCopyLink => 'リンクをコピー';

  @override
  String get shareSheetCopied => 'コピーしました';
}
