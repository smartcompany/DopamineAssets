import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import '../../auth/account_suspension_ui.dart';
import '../../auth/dopamine_community_profile_gate.dart';
import '../../auth/dopamine_user.dart';
import '../../auth/present_dopamine_auth_screen.dart';
import '../../core/badges/badge_unlock_center.dart';
import '../../core/config/api_config.dart';
import '../../core/navigation/home_shell_bottom_inset.dart';
import '../../core/navigation/home_shell_navigation.dart';
import '../../core/profile/profile_stats_store.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../core/push/push_prefs_keys.dart';
import '../../core/text/ugc_banned_words.dart';
import '../../core/storage/community_post_image_upload.dart';
import '../legal/privacy_processing_consent.dart';
import '../../data/models/community_post.dart';
import '../../data/models/profile_activity_item.dart';
import '../../data/models/ranked_asset.dart';
import '../../theme/dopamine_theme.dart';
import '../../widgets/run_with_fullscreen_loading.dart';
import '../asset/asset_detail_screen.dart';
import '../asset/asset_news_webview_screen.dart';
import '../community/community_compose_screen.dart';
import '../community/community_post_card.dart';
import '../community/community_post_detail_screen.dart';
import 'blocked_users_screen.dart';
import 'follow_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _maxBioLength = 400;
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  StreamSubscription<User?>? _authSub;
  HomeShellNavigation? _shellNav;
  AuthProvider<DopamineUser>? _authProvider;

  /// 홈(0) · 커뮤니티(1) · 프로필(2) — 프로필 탭으로 **들어올 때만** 갱신
  int _prevShellTabIndex = -1;

  bool _loading = false;
  Object? _loadError;
  List<ProfileActivityItem> _activity = const [];
  final Set<String> _activityLikeBusyIds = {};

  bool _savingName = false;
  bool _savingBio = false;

  /// [TextEditingController.text] trim 값이 중복 확인을 통과한 경우에만 저장 허용.
  String? _verifiedTrimmedName;
  bool _checkingDisplayName = false;
  bool _uploadingPhoto = false;
  bool _syncingProfileFromServer = false;
  bool _pushPrefsLoading = false;
  bool _pushMasterEnabled = true;
  bool _pushSocialReply = true;
  bool _pushSocialLike = true;
  bool _pushMarketDaily = true;
  bool _pushHotMoverDiscussion = true;
  final Set<String> _seenUnlockedBadgeKeys = <String>{};
  bool _badgeProgressArmed = false;
  _ProfileBadgeVm? _newBadgeToast;
  Timer? _newBadgeToastTimer;

  bool _isAppSignedIn(AuthProvider<DopamineUser> auth) {
    return auth.isLoggedIn();
  }

  /// 서버 프로필을 먼저 조회한다. 있으면 그대로 반영만 하고, 없으면 Firebase 표시 이름으로 생성·저장한다.
  Future<void> _syncProfileFromServer({
    required AuthProvider<DopamineUser> auth,
    required User firebaseUser,
  }) async {
    if (_syncingProfileFromServer) return;
    _syncingProfileFromServer = true;
    try {
      final token = await firebaseUser.getIdToken();
      if (token == null || token.isEmpty) return;

      final existing = await DopamineApi.fetchProfileMe(idToken: token);
      if (existing != null) {
        auth.setUserProfile(existing);
        if (!mounted) return;
        _syncNameField(existing.displayName);
        _syncBioField(existing.bio);
        return;
      }

      // 서버에 프로필 행이 없으면 소셜 표시 이름으로 자동 등록하지 않고 빈 필드로 둡니다.
      final firebaseName = firebaseUser.displayName?.trim();
      if (firebaseName != null && firebaseName.isNotEmpty) {
        var taken = false;
        try {
          taken = !await DopamineApi.fetchDisplayNameAvailable(
            idToken: token,
            displayName: firebaseName,
          );
        } catch (_) {
          taken = false;
        }
        if (taken) {
          if (!mounted) return;
          auth.setUserProfile(null);
          _nameController.clear();
          _bioController.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            unawaited(_showDuplicateSocialNameDialog(firebaseName));
          });
          return;
        }
      }

      if (!mounted) return;
      auth.setUserProfile(null);
      _nameController.clear();
      _bioController.clear();
    } catch (e) {
      debugPrint('[Profile] sync profile from server failed: $e');
    } finally {
      _syncingProfileFromServer = false;
    }
  }

  void _onNameDraftChanged() {
    if (!mounted) return;
    final t = _nameController.text.trim();
    if (_verifiedTrimmedName != null && t != _verifiedTrimmedName) {
      setState(() => _verifiedTrimmedName = null);
    } else {
      setState(() {});
    }
  }

  void _onBadgeCatalogChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    BadgeUnlockCenter.instance.addListener(_onBadgeCatalogChanged);
    unawaited(BadgeUnlockCenter.instance.ensureInitialized());
    _nameController.addListener(_onNameDraftChanged);
    _authProvider = context.read<AuthProvider<DopamineUser>>();
    _authProvider!.addListener(_handleAuthProviderUpdate);
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) async {
      if (!mounted) return;
      final auth = context.read<AuthProvider<DopamineUser>>();
      if (_isAppSignedIn(auth) && u != null) {
        await _syncProfileFromServer(auth: auth, firebaseUser: u);
        await _loadData();
      } else {
        ProfileStatsStore.instance.clear();
        setState(() {
          _activity = const [];
          _loadError = null;
          _loading = false;
          _nameController.clear();
          _newBadgeToast = null;
        });
        _seenUnlockedBadgeKeys.clear();
        _badgeProgressArmed = false;
      }
    });
  }

  void _handleShellNav() {
    final nav = _shellNav;
    if (nav == null || !mounted) return;
    final t = nav.tabIndex;
    if (t == 3 && _prevShellTabIndex != 3) {
      final auth = context.read<AuthProvider<DopamineUser>>();
      if (_isAppSignedIn(auth) && FirebaseAuth.instance.currentUser != null) {
        // 프로필 탭 진입 시에는 활동 내역만 조용히 갱신합니다.
        _reloadActivityOnly();
      }
    }
    _prevShellTabIndex = t;
  }

  Future<void> _reloadActivityOnly() async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    final token = await fb.getIdToken();
    if (token == null || token.isEmpty) return;
    try {
      final act = await DopamineApi.fetchProfileActivity(idToken: token);
      if (!mounted) return;
      setState(() {
        _activity = act;
      });
      _syncBadgeUnlockProgress(allowAnimation: _badgeProgressArmed);
    } catch (_) {
      // 탭 진입 동기화는 조용히 처리합니다.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<HomeShellNavigation>();
    if (!identical(_shellNav, nav)) {
      _shellNav?.removeListener(_handleShellNav);
      _shellNav = nav;
      _prevShellTabIndex = nav.tabIndex;
      _shellNav!.addListener(_handleShellNav);
    }
  }

  @override
  void dispose() {
    BadgeUnlockCenter.instance.removeListener(_onBadgeCatalogChanged);
    _newBadgeToastTimer?.cancel();
    _nameController.removeListener(_onNameDraftChanged);
    _shellNav?.removeListener(_handleShellNav);
    _authSub?.cancel();
    _authProvider?.removeListener(_handleAuthProviderUpdate);
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _handleAuthProviderUpdate() {
    if (!mounted) return;
    if (_savingName || _savingBio) return;

    final p = _authProvider?.userProfile;
    if (p == null) return;

    // 재로그인 시점에 auth.userProfile이 늦게 들어오면,
    // 기존 authStateChanges 콜백에서 동기화가 먼저 끝나서 이름이 안 보일 수 있습니다.
    // provider 업데이트를 감지해서 컨트롤러를 다시 채웁니다. (빈 닉네임도 반영)
    final normalized = p.displayName.trim();
    final nameChanged = _nameController.text.trim() != normalized;
    final bioNormalized = (p.bio ?? '').trim();
    final bioChanged = _bioController.text.trim() != bioNormalized;
    // 닉네임만 바뀔 때만 setState 하면 photoUrl 만 갱신될 때 화면이 안 돌아가
    // (앱 재시작 후에는 정상) — 프로필 사진 표시 누락 원인.
    setState(() {
      if (nameChanged) {
        _nameController.text = normalized;
        _verifiedTrimmedName = null;
      }
      if (bioChanged) {
        _bioController.text = bioNormalized;
      }
    });
  }

  void _syncNameField(String? displayName) {
    _nameController.text = (displayName ?? '').trim();
    _verifiedTrimmedName = null;
  }

  void _syncBioField(String? bio) {
    _bioController.text = (bio ?? '').trim();
  }

  String _extFromPath(String path) {
    final i = path.lastIndexOf('.');
    if (i < 0 || i >= path.length - 1) return 'jpg';
    return path.substring(i + 1).toLowerCase();
  }

  String _mimeForExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _pickProfilePhoto(AppLocalizations l10n) async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    debugPrint('[profile-photo] pick start uid=${fb.uid}');
    final files = await MediaPickerService.pickImages(
      context,
      maxCount: 1,
      // 서버 업로드 제한(5MB) 전에 클라이언트에서 축소한다.
      compress: true,
      maxWidth: 1080,
      maxHeight: 1080,
      quality: 72,
      compressFailureMessage: l10n.profilePhotoCompressFailed,
    );
    debugPrint('[profile-photo] picker result files=${files?.length ?? -1}');
    if (files == null || files.isEmpty) return;
    final x = files.first;
    if (!mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final ext = _extFromPath(x.path);
      debugPrint('[profile-photo] selected path=${x.path} ext=$ext');
      final bytes = await x.readAsBytes();
      debugPrint('[profile-photo] read bytes length=${bytes.length}');
      final token = await fb.getIdToken();
      if (token == null || token.isEmpty) return;
      debugPrint('[profile-photo] idToken acquired');
      final url = await uploadProfileImage(
        idToken: token,
        bytes: bytes,
        filename: 'avatar.$ext',
        contentType: _mimeForExt(ext),
      );
      debugPrint('[profile-photo] uploadProfileImage url=$url');
      await DopamineApi.patchProfilePhotoUrl(idToken: token, photoUrl: url);
      debugPrint('[profile-photo] patchProfilePhotoUrl success');
      if (!mounted) return;
      final auth = context.read<AuthProvider<DopamineUser>>();
      final current = auth.userProfile;
      auth.setUserProfile(
        DopamineUser(
          uid: current?.uid ?? fb.uid,
          displayName: current?.displayName ?? (fb.displayName?.trim() ?? ''),
          photoUrl: url,
          bio: current?.bio,
          suspendedUntil: current?.suspendedUntil,
        ),
      );
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profilePhotoSaved)));
    } catch (e) {
      debugPrint('[profile-photo] upload failed error=$e');
      if (!mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _removeProfilePhoto(AppLocalizations l10n) async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final token = await fb.getIdToken();
      if (token == null || token.isEmpty) return;
      await DopamineApi.patchProfilePhotoUrl(idToken: token, photoUrl: null);
      if (!mounted) return;
      final auth = context.read<AuthProvider<DopamineUser>>();
      final current = auth.userProfile;
      auth.setUserProfile(
        DopamineUser(
          uid: current?.uid ?? fb.uid,
          displayName: current?.displayName ?? (fb.displayName?.trim() ?? ''),
          photoUrl: null,
          bio: current?.bio,
          suspendedUntil: current?.suspendedUntil,
        ),
      );
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profilePhotoRemoved)));
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _loadData({bool showLoading = true}) async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;

    final auth = context.read<AuthProvider<DopamineUser>>();
    _syncNameField(auth.userProfile?.displayName);
    _syncBioField(auth.userProfile?.bio);

    final token = await fb.getIdToken();
    if (token == null || token.isEmpty) return;

    if (showLoading) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final me = await DopamineApi.fetchProfileMe(idToken: token);
      if (me != null && mounted) {
        context.read<AuthProvider<DopamineUser>>().setUserProfile(me);
        _syncNameField(me.displayName);
        _syncBioField(me.bio);
      }
      final results = await Future.wait<dynamic>([
        DopamineApi.fetchProfileStats(idToken: token),
        DopamineApi.fetchProfileActivity(idToken: token),
        DopamineApi.fetchPushPrefs(idToken: token),
      ]);
      final stats = results[0] as ProfileStats;
      final act = results[1] as List<ProfileActivityItem>;
      final push = results[2] as Map<String, dynamic>;
      if (!mounted) return;
      ProfileStatsStore.instance.apply(stats);
      setState(() {
        _activity = act;
        _pushMasterEnabled = _pushPrefBool(push, 'master_enabled');
        _pushSocialReply = _pushPrefBool(push, 'social_reply');
        _pushSocialLike = _pushPrefBool(push, 'social_like');
        _pushMarketDaily = _pushPrefBool(push, 'market_daily_brief');
        _pushHotMoverDiscussion = _pushPrefBool(
          push,
          PushPrefsKeys.hotMoverDiscussion,
        );
        _loading = false;
      });
      _syncBadgeUnlockProgress(allowAnimation: _badgeProgressArmed);
      _badgeProgressArmed = true;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  bool _pushPrefBool(Map<String, dynamic> prefs, String key) {
    final v = prefs[key];
    return v is bool ? v : true;
  }

  Map<String, bool> _pushSnapshot({
    bool? master,
    bool? reply,
    bool? like,
    bool? daily,
    bool? hotMover,
  }) {
    return <String, bool>{
      PushPrefsKeys.masterEnabled: master ?? _pushMasterEnabled,
      PushPrefsKeys.socialReply: reply ?? _pushSocialReply,
      PushPrefsKeys.socialLike: like ?? _pushSocialLike,
      PushPrefsKeys.marketDailyBrief: daily ?? _pushMarketDaily,
      PushPrefsKeys.hotMoverDiscussion: hotMover ?? _pushHotMoverDiscussion,
    };
  }

  Future<void> _togglePushPref(String key, bool value) async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    final token = await fb.getIdToken();
    if (token == null || token.isEmpty) return;
    if (!mounted) return;

    // 토글 적용 후의 전체 상태 스냅샷을 서버에 한 번에 보냅니다.
    var master = _pushMasterEnabled;
    var reply = _pushSocialReply;
    var like = _pushSocialLike;
    var daily = _pushMarketDaily;
    var hotMover = _pushHotMoverDiscussion;
    switch (key) {
      case PushPrefsKeys.masterEnabled:
        master = value;
        break;
      case PushPrefsKeys.socialReply:
        reply = value;
        break;
      case PushPrefsKeys.socialLike:
        like = value;
        break;
      case PushPrefsKeys.marketDailyBrief:
        daily = value;
        break;
      case PushPrefsKeys.hotMoverDiscussion:
        hotMover = value;
        break;
    }
    debugPrint(
      '[PushPrefs][UI] toggle key=$key value=$value'
      ' current=${_pushSnapshot()} next=${_pushSnapshot(master: master, reply: reply, like: like, daily: daily, hotMover: hotMover)}',
    );

    setState(() => _pushPrefsLoading = true);
    try {
      final payload = <String, dynamic>{
        PushPrefsKeys.masterEnabled: master,
        PushPrefsKeys.socialReply: reply,
        PushPrefsKeys.socialLike: like,
        PushPrefsKeys.marketDailyBrief: daily,
        PushPrefsKeys.hotMoverDiscussion: hotMover,
      };
      debugPrint('[PushPrefs][UI] PATCH payload=$payload');
      final updated = await DopamineApi.patchPushPrefs(
        idToken: token,
        patch: payload,
      );
      debugPrint('[PushPrefs][UI] PATCH response=$updated');
      if (!mounted) return;
      setState(() {
        _pushMasterEnabled = _pushPrefBool(
          updated,
          PushPrefsKeys.masterEnabled,
        );
        _pushSocialReply = _pushPrefBool(updated, PushPrefsKeys.socialReply);
        _pushSocialLike = _pushPrefBool(updated, PushPrefsKeys.socialLike);
        _pushMarketDaily = _pushPrefBool(
          updated,
          PushPrefsKeys.marketDailyBrief,
        );
        _pushHotMoverDiscussion = _pushPrefBool(
          updated,
          PushPrefsKeys.hotMoverDiscussion,
        );
      });
      debugPrint('[PushPrefs][UI] state updated=${_pushSnapshot()}');
    } catch (e) {
      debugPrint('[PushPrefs][UI] PATCH failed: $e');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _pushPrefsLoading = false);
    }
  }

  Future<void> _showDuplicateSocialNameDialog(String name) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileDisplayNameDuplicateFromSocialTitle),
        content: Text(l10n.profileDisplayNameDuplicateFromSocialMessage(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.profileDisplayNameDuplicateFromSocialOk),
          ),
        ],
      ),
    );
  }

  Future<void> _checkDisplayNameDuplicate(AppLocalizations l10n) async {
    final text = _nameController.text.trim();
    if (text.isEmpty || text.length > 80) return;

    final bad = UgcBannedWords.firstMatch(text);
    if (bad != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.ugcBannedWordsMessage(bad))));
      return;
    }

    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;

    final auth = context.read<AuthProvider<DopamineUser>>();
    final committed = (auth.userProfile?.displayName ?? '').trim();
    if (committed.isNotEmpty && text.toLowerCase() == committed.toLowerCase()) {
      return;
    }

    setState(() => _checkingDisplayName = true);
    try {
      final token = await fb.getIdToken();
      if (token == null || token.isEmpty) return;

      try {
        final ok = await DopamineApi.fetchDisplayNameAvailable(
          idToken: token,
          displayName: text,
        );
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.profileDisplayNameTaken)));
          return;
        }
        setState(() => _verifiedTrimmedName = text);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorLoadFailed)));
      }
    } finally {
      if (mounted) setState(() => _checkingDisplayName = false);
    }
  }

  Future<void> _saveDisplayName(AppLocalizations l10n) async {
    final text = _nameController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileDisplayNameEmpty)));
      return;
    }
    if (text.length > 80) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorLoadFailed)));
      return;
    }

    final bad = UgcBannedWords.firstMatch(text);
    if (bad != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.ugcBannedWordsMessage(bad))));
      return;
    }

    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;

    final auth = context.read<AuthProvider<DopamineUser>>();
    final committed = (auth.userProfile?.displayName ?? '').trim();
    final unchanged =
        committed.isNotEmpty && text.toLowerCase() == committed.toLowerCase();
    if (unchanged) return;

    if (_verifiedTrimmedName != text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileDisplayNameCheckFirst)),
      );
      return;
    }

    setState(() => _savingName = true);
    try {
      final token = await fb.getIdToken();
      if (token == null || token.isEmpty) return;

      await DopamineApi.patchProfileDisplayName(
        idToken: token,
        displayName: text,
      );
      if (!mounted) return;
      final current = auth.userProfile;
      auth.setUserProfile(
        DopamineUser(
          uid: fb.uid,
          displayName: text,
          photoUrl: current?.photoUrl,
          bio: current?.bio,
          suspendedUntil: current?.suspendedUntil,
        ),
      );
      if (!mounted) return;
      setState(() => _verifiedTrimmedName = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileDisplayNameSaved)));
      await _loadData();
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.message == 'display_name_taken'
          ? l10n.profileDisplayNameTaken
          : e.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _saveBio(AppLocalizations l10n) async {
    final draft = _bioController.text.trim();
    if (draft.length > _maxBioLength) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorLoadFailed)));
      return;
    }

    final bad = UgcBannedWords.firstMatch(draft);
    if (bad != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.ugcBannedWordsMessage(bad))));
      return;
    }

    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;

    final auth = context.read<AuthProvider<DopamineUser>>();
    final committed = (auth.userProfile?.bio ?? '').trim();
    final unchanged = draft == committed;
    if (unchanged) return;

    setState(() => _savingBio = true);
    try {
      final token = await fb.getIdToken();
      if (token == null || token.isEmpty) return;

      await DopamineApi.patchProfileBio(
        idToken: token,
        bio: draft.isEmpty ? null : draft,
      );
      if (!mounted) return;
      final current = auth.userProfile;
      final nextBio = draft.isEmpty ? null : draft;
      auth.setUserProfile(
        DopamineUser(
          uid: fb.uid,
          displayName: current?.displayName ?? '',
          photoUrl: current?.photoUrl,
          bio: nextBio,
          suspendedUntil: current?.suspendedUntil,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileBioSaved)));
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _savingBio = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileDeleteTitle),
        content: Text(l10n.profileDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.profileDeleteCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DopamineTheme.accentRed,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.profileDeleteConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider<DopamineUser>>();
    final uid = auth.currentUid();
    if (uid == null || uid.isEmpty) return;

    try {
      final token = await auth.getIdToken();
      if (token == null || token.isEmpty) {
        throw StateError('invalid-id-token');
      }
      debugPrint(
        '[Dopamine][delete-account] request /api/profile/me uid=$uid tokenLen=${token.length}',
      );

      try {
        await DopamineApi.deleteProfileData(idToken: token);
      } on ApiException catch (e) {
        debugPrint(
          '[Dopamine][delete-account] deleteProfileData failed: ${e.message}',
        );
        if (!context.mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
        return;
      } catch (e) {
        debugPrint('[Dopamine][delete-account] deleteProfileData failed: $e');
        if (!context.mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorLoadFailed)));
        return;
      }

      try {
        await auth.deleteAccount();
        await clearPrivacyProcessingConsent();
      } on FirebaseAuthException catch (e) {
        debugPrint(
          '[Dopamine][delete-account] auth.deleteAccount failed: code=${e.code} message=${e.message}',
        );
        if (!context.mounted) return;
        if (e.code == 'requires-recent-login') {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.profileRequiresRecentLogin)),
          );
        } else {
          messenger.showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
        }
        return;
      } catch (e) {
        debugPrint('[Dopamine][delete-account] auth.deleteAccount failed: $e');
        if (!context.mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorLoadFailed)));
        return;
      }
    } on StateError {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorLoadFailed)));
    } catch (e) {
      debugPrint('[Dopamine][delete-account] unexpected failed: $e');
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorLoadFailed)));
    }
  }

  Future<void> _logout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await clearPrivacyProcessingConsent();
    if (!context.mounted) return;
    await context.read<AuthProvider<DopamineUser>>().logout();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileLogoutDone)));
    }
  }

  String _activityKindLabel(AppLocalizations l10n, String kind) {
    switch (kind) {
      case 'my_post':
        return l10n.profileActivityMyPost;
      case 'my_reply':
        return l10n.profileActivityMyReply;
      case 'reply_on_my_post':
        return l10n.profileActivityReplyOnPost;
      case 'like_received':
        return l10n.profileActivityLikeReceived;
      default:
        return kind;
    }
  }

  Future<void> _openActivityItem(
    BuildContext context,
    ProfileActivityItem item,
  ) async {
    AssetDetailScreen.open(
      context,
      RankedAsset.communityShell(
        symbol: item.assetSymbol,
        assetClass: item.assetClass,
      ),
    );
  }

  /// like_received / reply_on_my_post → 커뮤니티 게시글 본문(스레드 루트)
  Future<void> _openActivityThreadPost(
    BuildContext context,
    ProfileActivityItem item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) {
      await presentDopamineAuthScreen(context);
      return;
    }
    final token = await fb.getIdToken();
    if (token == null || token.isEmpty || !mounted) return;

    var rootId = item.threadRootCommentId?.trim();
    if (rootId == null || rootId.isEmpty) {
      rootId = await _resolveThreadRootCommentIdViaApi(
        commentId: item.commentId,
        idToken: token,
      );
    }
    if (rootId == null || rootId.isEmpty || !context.mounted) return;

    try {
      final root = await DopamineApi.fetchAssetCommentById(
        id: rootId,
        idToken: token,
      );
      if (!context.mounted) return;
      final post = CommunityPost(
        id: root.id,
        body: root.body,
        title: root.title,
        imageUrls: root.imageUrls,
        authorUid: root.authorUid,
        authorDisplayName: root.authorDisplayName,
        authorPhotoUrl: null,
        createdAt: root.createdAt,
        assetSymbol: root.assetSymbol ?? item.assetSymbol,
        assetClass: root.assetClass ?? item.assetClass,
        assetDisplayName: root.assetDisplayName ?? item.assetDisplayName,
        replyCount: 0,
        likeCount: root.likeCount,
        likedByMe: root.likedByMe,
        moderationHiddenFromPublic: root.moderationHiddenFromPublic,
      );
      await _openActivityPostDetail(post);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<String?> _resolveThreadRootCommentIdViaApi({
    required String commentId,
    required String idToken,
  }) async {
    var cur = commentId;
    for (var i = 0; i < 50; i++) {
      final c = await DopamineApi.fetchAssetCommentById(
        id: cur,
        idToken: idToken,
      );
      final p = c.parentId?.trim();
      if (p == null || p.isEmpty) return c.id;
      cur = p;
    }
    return cur;
  }

  Future<void> _editOwnActivity(
    BuildContext context,
    ProfileActivityItem item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await ensureCommunityIdentity(context)) return;
    if (!context.mounted) return;
    if (!await ensureNotSuspendedWithRefresh(context)) {
      return;
    }
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => CommunityComposeScreen(editCommentId: item.commentId),
      ),
    );
    if ((result == true || result is CommunityPost) && mounted) {
      await _loadData();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileActivityPostUpdated)));
    }
  }

  ProfileActivityItem? _activityItemForCommentId(String commentId) {
    for (final a in _activity) {
      if (a.commentId == commentId) return a;
    }
    return null;
  }

  Future<void> _openActivityPostDetail(CommunityPost p) async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    final changed = await CommunityPostDetailScreen.open(
      context,
      post: p,
      myUid: fb.uid,
      onPostUpdated: (_) {
        if (mounted) {
          _loadData(showLoading: false);
        }
      },
    );
    if (changed && mounted) {
      await _loadData();
    }
  }

  Future<void> _toggleActivityLike(CommunityPost p) async {
    final l10n = AppLocalizations.of(context)!;
    if (_activityLikeBusyIds.contains(p.id)) return;
    if (!await ensureCommunityIdentity(context, showLoginHintSnack: true)) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !mounted) return;
    final token = await user.getIdToken();
    if (token == null || !mounted) return;
    setState(() => _activityLikeBusyIds.add(p.id));
    try {
      await DopamineApi.toggleCommentLike(idToken: token, commentId: p.id);
      if (!mounted) return;
      await _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorLoadFailed)));
    } finally {
      if (mounted) setState(() => _activityLikeBusyIds.remove(p.id));
    }
  }

  Future<void> _deleteOwnActivity(
    BuildContext context,
    ProfileActivityItem item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await ensureNotSuspendedWithRefresh(context)) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.profileActivityDeleteDialogTitle),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.profileDeleteCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l10n.profileActivityDeletePost,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;
    try {
      await runWithFullscreenLoading<void>(
        context,
        (() async {
          final fb = FirebaseAuth.instance.currentUser;
          if (fb == null) return;
          final token = await fb.getIdToken();
          if (token == null || token.isEmpty) return;
          await DopamineApi.deleteAssetComment(
            id: item.commentId,
            idToken: token,
          );
          if (!context.mounted) return;
          context.read<HomeShellNavigation>().bumpCommunityFeedEpoch();
          await _loadData();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.profileActivityPostDeleted)),
          );
        })(),
      );
    } catch (e) {
      if (!context.mounted) return;
      // 이미 다른 화면에서 지워진 항목이면 로컬 목록만 정리하고 성공으로 간주합니다.
      if (e is ApiException && e.message.toLowerCase().contains('not found')) {
        context.read<HomeShellNavigation>().bumpCommunityFeedEpoch();
        setState(() {
          _activity = _activity
              .where((a) => a.commentId != item.commentId)
              .toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileActivityPostDeleted)),
        );
        unawaited(_loadData());
        return;
      }
      final msg = e is ApiException ? e.message : l10n.errorLoadFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Widget _activityActionButtons(
    BuildContext context,
    ProfileActivityItem item,
    AppLocalizations l10n,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 22),
          color: DopamineTheme.textSecondary,
          tooltip: l10n.profileActivityEditPost,
          onPressed: () => _editOwnActivity(context, item),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 22),
          color: DopamineTheme.textSecondary,
          tooltip: l10n.profileActivityDeletePost,
          onPressed: () => _deleteOwnActivity(context, item),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    String locale,
    ProfileActivityItem item,
  ) {
    final timeStr = DateFormat.yMMMd(locale).add_jm().format(item.at.toLocal());

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
    );

    if ((item.kind == 'my_post' || item.kind == 'my_reply') &&
        !item.hasCommunityCardPayload) {
      return Card(
        clipBehavior: Clip.antiAlias,
        color: Colors.black.withValues(alpha: 0.38),
        elevation: 0,
        shape: cardShape,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _openActivityItem(context, item),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.kind == 'my_post'
                              ? l10n.profileActivityPostOnAsset(
                                  (item.assetDisplayName?.trim().isNotEmpty ==
                                          true)
                                      ? item.assetDisplayName!.trim()
                                      : item.assetSymbol,
                                )
                              : _activityKindLabel(l10n, item.kind),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: DopamineTheme.neonGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.bodyPreview,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: DopamineTheme.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          timeStr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: DopamineTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _activityActionButtons(context, item, l10n),
            ],
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      color: Colors.black.withValues(alpha: 0.38),
      elevation: 0,
      shape: cardShape,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          if (item.kind == 'like_received' || item.kind == 'reply_on_my_post') {
            _openActivityThreadPost(context, item);
          } else {
            _openActivityItem(context, item);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _activityKindLabel(l10n, item.kind),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: DopamineTheme.neonGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.bodyPreview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DopamineTheme.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                timeStr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: DopamineTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignedInBody(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    User fb,
    bool profileSaved,
    String? profilePhotoUrl,
    String locale,
    String committedDisplayNameTrimmed,
    String committedBioTrimmed, {
    required bool showSuspensionBanner,
  }) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.profileSignedInSection,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: DopamineTheme.neonGreen,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.profileAccountRefreshTooltip,
                        onPressed: _loading ? null : () => _loadData(),
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: _loading
                              ? DopamineTheme.textSecondary.withValues(
                                  alpha: 0.35,
                                )
                              : DopamineTheme.textSecondary,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.profileSettingsTitle,
                        onPressed: _openSettingsScreen,
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: DopamineTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (showSuspensionBanner) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: DopamineTheme.accentRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DopamineTheme.accentRed.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 22,
                            color: DopamineTheme.accentRed.withValues(
                              alpha: 0.95,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.accountSuspendedBanner,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: DopamineTheme.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _AccountProfilePhotoCard(
                    theme: theme,
                    l10n: l10n,
                    photoUrl: profilePhotoUrl,
                    profileSaved: profileSaved,
                    uploadingPhoto: _uploadingPhoto,
                    onPickPhoto: () => _pickProfilePhoto(l10n),
                    onRemovePhoto: () => _removeProfilePhoto(l10n),
                    onOpenBadges: () => _showBadgesBottomSheet(context, theme),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.profileDisplayName,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: DopamineTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final committed = committedDisplayNameTrimmed;
                      final draft = _nameController.text.trim();
                      final draftValid = draft.isNotEmpty && draft.length <= 80;
                      final nameUnchanged =
                          committed.isNotEmpty &&
                          draft.toLowerCase() == committed.toLowerCase();
                      final verifiedForDraft =
                          _verifiedTrimmedName != null &&
                          _verifiedTrimmedName == draft;
                      final busy = _savingName || _checkingDisplayName;
                      final VoidCallback? nameAction = busy
                          ? null
                          : nameUnchanged
                          ? null
                          : verifiedForDraft
                          ? () => _saveDisplayName(l10n)
                          : draftValid
                          ? () => _checkDisplayNameDuplicate(l10n)
                          : null;
                      final String nameActionLabel = nameUnchanged
                          ? l10n.profileSaveDisplayName
                          : verifiedForDraft
                          ? l10n.profileSaveDisplayName
                          : l10n.profileCheckDisplayNameDuplicate;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              onTapOutside: (_) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              maxLength: 80,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: DopamineTheme.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: committed.isEmpty
                                    ? l10n.profileDisplayNameInputPlaceholder
                                    : l10n.profileDisplayNameHint,
                                hintStyle: TextStyle(
                                  color: DopamineTheme.textSecondary.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.black.withValues(alpha: 0.22),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                counterText: '',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed: nameAction,
                            style: FilledButton.styleFrom(
                              backgroundColor: DopamineTheme.neonGreen,
                              foregroundColor: const Color(0xFF0A0A0A),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                            child: _savingName || _checkingDisplayName
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0A0A0A),
                                    ),
                                  )
                                : Text(nameActionLabel),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: DopamineTheme.neonGreen.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: Builder(
                        builder: (ctx) {
                          final draftBio = _bioController.text.trim();
                          final bioDirty = draftBio != committedBioTrimmed;
                          final bioAction = _savingBio
                              ? null
                              : bioDirty
                              ? () => _saveBio(l10n)
                              : null;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 18,
                                      color: DopamineTheme.neonGreen.withValues(
                                        alpha: 0.62,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      l10n.profileBioLabel,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: DopamineTheme.neonGreen
                                                .withValues(alpha: 0.92),
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.15,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _bioController,
                                onChanged: (_) => setState(() {}),
                                maxLength: _maxBioLength,
                                maxLines: 5,
                                minLines: 3,
                                onTapOutside: (_) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: DopamineTheme.textPrimary,
                                  height: 1.38,
                                ),
                                decoration: InputDecoration(
                                  hintText: '',
                                  filled: true,
                                  fillColor: Colors.black.withValues(
                                    alpha: 0.28,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.10,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: DopamineTheme.neonGreen.withValues(
                                        alpha: 0.50,
                                      ),
                                    ),
                                  ),
                                  counterText: '',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.fromLTRB(
                                    14,
                                    14,
                                    14,
                                    14,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${_bioController.text.characters.length}/$_maxBioLength',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: DopamineTheme.textSecondary
                                                .withValues(alpha: 0.9),
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                    ),
                                    const Spacer(),
                                    FilledButton(
                                      onPressed: bioAction,
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            DopamineTheme.neonGreen,
                                        foregroundColor: const Color(
                                          0xFF0A0A0A,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: _savingBio
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF0A0A0A),
                                              ),
                                            )
                                          : Text(l10n.profileSaveBio),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (ProfileStatsStore.instance.stats == null && _loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DopamineTheme.neonGreen,
                          ),
                        ),
                      ),
                    )
                  else if (ProfileStatsStore.instance.stats == null &&
                      _loadError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _loadError is ApiException
                            ? (_loadError as ApiException).message
                            : l10n.errorLoadFailed,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: DopamineTheme.accentRed,
                        ),
                      ),
                    )
                  else if (ProfileStatsStore.instance.stats != null)
                    _StatsRow(
                      stats: ProfileStatsStore.instance.stats!,
                      l10n: l10n,
                    ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _logout(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DopamineTheme.textPrimary,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.profileLogout),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _confirmDelete(context),
                      style: TextButton.styleFrom(
                        foregroundColor: DopamineTheme.accentRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.profileDeleteAccount),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProfileStickyHeaderDelegate(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.profileActivityTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: DopamineTheme.neonGreen,
                  ),
                ),
              ),
            ),
          ),
        ];
      },
      body: _buildActivityList(
        context,
        theme,
        l10n,
        fb,
        profilePhotoUrl,
        locale,
      ),
    );
  }

  Widget _pushToggleRow({
    required BuildContext context,
    required String label,
    required bool value,
    required Future<void> Function(bool value) onChanged,
    bool enabled = true,
  }) {
    final active = enabled && !_pushPrefsLoading;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DopamineTheme.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: active ? onChanged : null,
            activeThumbColor: DopamineTheme.neonGreen,
          ),
        ],
      ),
    );
  }

  Future<void> _openSettingsScreen() async {
    final l10n = AppLocalizations.of(context)!;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) {
          var master = _pushMasterEnabled;
          var reply = _pushSocialReply;
          var like = _pushSocialLike;
          var daily = _pushMarketDaily;
          var hotMover = _pushHotMoverDiscussion;
          final theme = Theme.of(ctx);
          return Scaffold(
            appBar: AppBar(title: Text(l10n.profileSettingsTitle)),
            body: SafeArea(
              child: StatefulBuilder(
                builder: (context, setSheetState) {
                  Future<void> toggle(String key, bool next) async {
                    setSheetState(() {
                      switch (key) {
                        case 'master_enabled':
                          master = next;
                          break;
                        case 'social_reply':
                          reply = next;
                          break;
                        case 'social_like':
                          like = next;
                          break;
                        case 'market_daily_brief':
                          daily = next;
                          break;
                        case 'hot_mover_discussion':
                          hotMover = next;
                          break;
                      }
                    });
                    await _togglePushPref(key, next);
                    setSheetState(() {
                      master = _pushMasterEnabled;
                      reply = _pushSocialReply;
                      like = _pushSocialLike;
                      daily = _pushMarketDaily;
                      hotMover = _pushHotMoverDiscussion;
                    });
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.profilePushTitle,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: DopamineTheme.neonGreen,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _pushToggleRow(
                              context: ctx,
                              label: l10n.profilePushMaster,
                              value: master,
                              onChanged: (v) =>
                                  toggle(PushPrefsKeys.masterEnabled, v),
                            ),
                            _pushToggleRow(
                              context: ctx,
                              label: l10n.profilePushSocialReply,
                              value: reply,
                              enabled: master,
                              onChanged: (v) =>
                                  toggle(PushPrefsKeys.socialReply, v),
                            ),
                            _pushToggleRow(
                              context: ctx,
                              label: l10n.profilePushSocialLike,
                              value: like,
                              enabled: master,
                              onChanged: (v) =>
                                  toggle(PushPrefsKeys.socialLike, v),
                            ),
                            _pushToggleRow(
                              context: ctx,
                              label: l10n.profilePushMarketDaily,
                              value: daily,
                              enabled: master,
                              onChanged: (v) =>
                                  toggle(PushPrefsKeys.marketDailyBrief, v),
                            ),
                            _pushToggleRow(
                              context: ctx,
                              label: l10n.profilePushHotMoverDiscussion,
                              value: hotMover,
                              enabled: master,
                              onChanged: (v) =>
                                  toggle(PushPrefsKeys.hotMoverDiscussion, v),
                            ),
                            if (_pushPrefsLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: SizedBox(
                                  height: 2,
                                  child: LinearProgressIndicator(
                                    color: DopamineTheme.neonGreen,
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Material(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: Icon(
                            Icons.gavel_outlined,
                            color: DopamineTheme.neonGreen.withValues(
                              alpha: 0.95,
                            ),
                          ),
                          title: Text(
                            l10n.profileSettingsLegalDisclosures,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: DopamineTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: DopamineTheme.textSecondary,
                          ),
                          onTap: () {
                            final lang = Localizations.localeOf(
                              context,
                            ).languageCode;
                            final hash = lang == 'ko' ? 'ko' : 'en';
                            final uri = Uri.parse(
                              '${ApiConfig.baseUrl}/legal/app-disclosures.html#$hash',
                            );
                            unawaited(
                              AssetNewsWebViewScreen.open(
                                context,
                                url: uri,
                                pageTitle: l10n.profileSettingsLegalDisclosures,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityList(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    User fb,
    String? profilePhotoUrl,
    String locale,
  ) {
    if (_loading && _activity.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DopamineTheme.neonGreen,
          ),
        ),
      );
    }

    if (_loadError != null && _activity.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _loadError is ApiException
                ? (_loadError as ApiException).message
                : l10n.errorLoadFailed,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DopamineTheme.accentRed,
            ),
          ),
        ),
      );
    }

    if (_activity.isEmpty) {
      return Center(
        child: Text(
          l10n.emptyState,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: DopamineTheme.textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        28 + homeShellBottomInset(context),
      ),
      itemCount: _activity.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _activity[index];
        return item.hasCommunityCardPayload
            ? CommunityPostCard(
                post: item.toCommunityPost(
                  authorUid: fb.uid,
                  fallbackAuthorDisplayName:
                      _nameController.text.trim().isNotEmpty
                      ? _nameController.text.trim()
                      : 'User',
                  authorPhotoUrl: profilePhotoUrl?.trim().isNotEmpty == true
                      ? profilePhotoUrl!.trim()
                      : null,
                ),
                myUid: fb.uid,
                likeInProgress: _activityLikeBusyIds.contains(item.commentId),
                onToggleLike: _toggleActivityLike,
                onOpenPostDetail: _openActivityPostDetail,
                onEditOwnPost: (p) {
                  final i = _activityItemForCommentId(p.id);
                  if (i != null) {
                    _editOwnActivity(context, i);
                  }
                },
                onDeleteOwnPost: (p) {
                  final i = _activityItemForCommentId(p.id);
                  if (i != null) {
                    _deleteOwnActivity(context, i);
                  }
                },
              )
            : _buildActivityCard(context, theme, l10n, locale, item);
      },
    );
  }

  int get _postCount => ProfileStatsStore.instance.stats?.postsCount ?? 0;

  int get _replyCount => _activity
      .where((e) => e.kind == 'my_reply' || e.kind == 'reply_on_post')
      .length;

  int get _likeReceivedCount =>
      _activity.where((e) => e.kind == 'like_received').length;

  int get _activityCount => _activity.length;
  bool get _communityExplored => _shellNav?.hasVisitedCommunity ?? false;

  int get _pseudoLevel {
    final score =
        (_postCount * 12) + (_replyCount * 6) + (_likeReceivedCount * 2);
    if (score >= 220) return 10;
    if (score >= 80) return 5;
    return 1;
  }

  void _syncBadgeUnlockProgress({required bool allowAnimation}) {
    final unlockedNow = _buildBadgeVms().where((b) => b.unlocked).toList();
    final unlockedKeysNow = unlockedNow.map((b) => b.key).toSet();
    final newlyUnlockedKeys = unlockedKeysNow.difference(
      _seenUnlockedBadgeKeys,
    );
    _seenUnlockedBadgeKeys
      ..clear()
      ..addAll(unlockedKeysNow);
    if (!allowAnimation || newlyUnlockedKeys.isEmpty || !mounted) return;
    final firstNew = unlockedNow.firstWhere(
      (b) => newlyUnlockedKeys.contains(b.key),
      orElse: () => unlockedNow.first,
    );
    _showNewBadgeToast(firstNew);
  }

  void _showNewBadgeToast(_ProfileBadgeVm badge) {
    _newBadgeToastTimer?.cancel();
    setState(() => _newBadgeToast = badge);
    _newBadgeToastTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _newBadgeToast = null);
    });
  }

  Widget _buildNewBadgeToast(ThemeData theme) {
    final badge = _newBadgeToast;
    if (badge == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return IgnorePointer(
      ignoring: false,
      child: GestureDetector(
        onTap: () => setState(() => _newBadgeToast = null),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFF111827).withValues(alpha: 0.96),
            border: Border.all(
              color: DopamineTheme.neonGreen.withValues(alpha: 0.55),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildBadgeImage(
                  badge.assetPath,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.profileBadgeToastUnlocked,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: DopamineTheme.neonGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      badge.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DopamineTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.emoji_events_rounded,
                color: DopamineTheme.neonGreen.withValues(alpha: 0.9),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeImage(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    final w = width;
    final h = height;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: w,
        height: h,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: w,
          height: h,
          color: Colors.white.withValues(alpha: 0.06),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_rounded, color: Colors.white54),
        ),
      );
    }
    return Container(
      width: w,
      height: h,
      color: Colors.white.withValues(alpha: 0.06),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: Colors.white.withValues(alpha: 0.35),
        size: ((w ?? h ?? 28) > 120) ? 48 : 22,
      ),
    );
  }

  List<_ProfileBadgeVm> _buildBadgeVms() {
    final l10n = AppLocalizations.of(context)!;
    String imageFor(String key) => BadgeUnlockCenter.instance.imageFor(key);
    final talked = _postCount + _replyCount;
    return [
      _ProfileBadgeVm(
        key: 'first',
        label: l10n.profileBadgeFirstTitle,
        assetPath: imageFor('first'),
        unlocked: BadgeUnlockCenter.instance.isUnlocked('first') || true,
        description: l10n.profileBadgeFirstDescription,
        requirementText: l10n.profileBadgeFirstRequirement,
      ),
      _ProfileBadgeVm(
        key: 'explorer',
        label: l10n.profileBadgeExplorerTitle,
        assetPath: imageFor('explorer'),
        unlocked:
            BadgeUnlockCenter.instance.isUnlocked('explorer') ||
            _communityExplored ||
            _activityCount >= 1,
        description: l10n.profileBadgeExplorerDescription,
        requirementText: l10n.profileBadgeExplorerRequirement,
      ),
      _ProfileBadgeVm(
        key: 'write_first',
        label: l10n.profileBadgeWriteFirstTitle,
        assetPath: imageFor('write_first'),
        unlocked:
            BadgeUnlockCenter.instance.isUnlocked('write_first') ||
            _postCount >= 1,
        description: l10n.profileBadgeWriteFirstDescription,
        requirementText: l10n.profileBadgeWriteFirstRequirement,
      ),
      _ProfileBadgeVm(
        key: 'comment_first',
        label: l10n.profileBadgeCommentFirstTitle,
        assetPath: imageFor('comment_first'),
        unlocked:
            BadgeUnlockCenter.instance.isUnlocked('comment_first') ||
            _replyCount >= 1,
        description: l10n.profileBadgeCommentFirstDescription,
        requirementText: l10n.profileBadgeCommentFirstRequirement,
      ),
      _ProfileBadgeVm(
        key: 'radar_on',
        label: l10n.profileBadgeRadarOnTitle,
        assetPath: imageFor('radar_on'),
        unlocked:
            BadgeUnlockCenter.instance.isUnlocked('radar_on') ||
            _activityCount >= 3,
        description: l10n.profileBadgeRadarOnDescription,
        requirementText: l10n.profileBadgeRadarOnRequirement,
      ),
      _ProfileBadgeVm(
        key: 'scan_assets',
        label: l10n.profileBadgeScanAssetsTitle,
        assetPath: imageFor('scan_assets'),
        unlocked:
            BadgeUnlockCenter.instance.isUnlocked('scan_assets') ||
            _activityCount >= 50,
        description: l10n.profileBadgeScanAssetsDescription,
        requirementText: l10n.profileBadgeScanAssetsRequirement,
      ),
      _ProfileBadgeVm(
        key: 'talk_king',
        label: l10n.profileBadgeTalkKingTitle,
        assetPath: imageFor('talk_king'),
        unlocked:
            BadgeUnlockCenter.instance.isUnlocked('talk_king') || talked >= 20,
        description: l10n.profileBadgeTalkKingDescription,
        requirementText: l10n.profileBadgeTalkKingRequirement,
      ),
      _ProfileBadgeVm(
        key: 'heart_king',
        label: l10n.profileBadgeHeartKingTitle,
        assetPath: imageFor('heart_king'),
        unlocked:
            BadgeUnlockCenter.instance.isUnlocked('heart_king') ||
            _likeReceivedCount >= 50,
        description: l10n.profileBadgeHeartKingDescription,
        requirementText: l10n.profileBadgeHeartKingRequirement,
      ),
      _ProfileBadgeVm(
        key: 'visit_7',
        label: l10n.profileBadgeVisit7Title,
        assetPath: imageFor('visit_7'),
        unlocked:
            BadgeUnlockCenter.instance.isUnlocked('visit_7') ||
            _activityCount >= 7,
        description: l10n.profileBadgeVisit7Description,
        requirementText: l10n.profileBadgeVisit7Requirement,
      ),
      _ProfileBadgeVm(
        key: 'level_5',
        label: l10n.profileBadgeLevel5Title,
        assetPath: imageFor('level_5'),
        unlocked:
            BadgeUnlockCenter.instance.isUnlocked('level_5') ||
            _pseudoLevel >= 5,
        description: l10n.profileBadgeLevel5Description,
        requirementText: l10n.profileBadgeLevel5Requirement,
      ),
      _ProfileBadgeVm(
        key: 'level_10',
        label: l10n.profileBadgeLevel10Title,
        assetPath: imageFor('level_10'),
        unlocked:
            BadgeUnlockCenter.instance.isUnlocked('level_10') ||
            _pseudoLevel >= 10,
        description: l10n.profileBadgeLevel10Description,
        requirementText: l10n.profileBadgeLevel10Requirement,
      ),
      _ProfileBadgeVm(
        key: 'multi_market',
        label: l10n.profileBadgeMultiMarketTitle,
        assetPath: imageFor('multi_market'),
        unlocked:
            BadgeUnlockCenter.instance.isUnlocked('multi_market') ||
            _activityCount >= 12,
        description: l10n.profileBadgeMultiMarketDescription,
        requirementText: l10n.profileBadgeMultiMarketRequirement,
      ),
    ];
  }

  Future<void> _showBadgeDetail(_ProfileBadgeVm badge) async {
    if (!mounted) return;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF121321),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        badge.label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: DopamineTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: DopamineTheme.textSecondary,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ColorFiltered(
                      colorFilter: badge.unlocked
                          ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            )
                          : ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.55),
                              BlendMode.srcATop,
                            ),
                      child: _buildBadgeImage(
                        badge.assetPath,
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  badge.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: DopamineTheme.textSecondary,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        badge.unlocked
                            ? Icons.check_circle_rounded
                            : Icons.lock_rounded,
                        size: 20,
                        color: badge.unlocked
                            ? DopamineTheme.neonGreen
                            : DopamineTheme.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          badge.unlocked
                              ? l10n.profileBadgeUnlocked
                              : l10n.profileBadgeRequirement(badge.requirementText),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: badge.unlocked
                                ? DopamineTheme.neonGreen
                                : DopamineTheme.textSecondary,
                            fontSize: 15,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBadgesBottomSheet(
    BuildContext context,
    ThemeData theme,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final badges = _buildBadgeVms();
    final unlocked = badges.where((b) => b.unlocked).length;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121321),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.of(ctx).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      l10n.profileBadgeSectionTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: DopamineTheme.neonGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$unlocked / ${badges.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: DopamineTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: badges.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.70,
                        ),
                    itemBuilder: (_, i) {
                      final b = badges[i];
                      return GestureDetector(
                        onTap: () => _showBadgeDetail(b),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ColorFiltered(
                                      colorFilter: b.unlocked
                                          ? const ColorFilter.mode(
                                              Colors.transparent,
                                              BlendMode.dst,
                                            )
                                          : ColorFilter.mode(
                                              Colors.black.withValues(
                                                alpha: 0.55,
                                              ),
                                              BlendMode.srcATop,
                                            ),
                                      child: _buildBadgeImage(
                                        b.assetPath,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    if (!b.unlocked)
                                      Container(
                                        color: Colors.black.withValues(
                                          alpha: 0.35,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.lock_rounded,
                                            size: 16,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              b.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: b.unlocked
                                    ? DopamineTheme.textPrimary
                                    : DopamineTheme.textSecondary,
                                fontSize: 13,
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider<DopamineUser>>();
    final fb = FirebaseAuth.instance.currentUser;
    final appSignedIn = _isAppSignedIn(auth);
    final locale = l10n.localeName;
    final profileSaved = appSignedIn;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: appSignedIn
                ? ListenableBuilder(
                    listenable: ProfileStatsStore.instance,
                    builder: (context, _) {
                      final committedName =
                          (auth.userProfile?.displayName ?? '').trim();
                      final committedBio = (auth.userProfile?.bio ?? '').trim();
                      // displayName 과 같이 Provider 에서 매번 읽는다. 상위 build 의
                      // profilePhotoUrl 스냅샷을 넘기면 StatsStore 알림만 올 때
                      // 부모가 안 돌아 아바타 URL 이 갱신되지 않을 수 있다.
                      final livePhotoUrl = auth.userProfile?.photoUrl;
                      return _buildSignedInBody(
                        context,
                        theme,
                        l10n,
                        fb!,
                        profileSaved,
                        livePhotoUrl,
                        locale,
                        committedName,
                        committedBio,
                        showSuspensionBanner: isDopamineUserSuspended(
                          auth.userProfile,
                        ),
                      );
                    },
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.profileNotSignedIn,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: DopamineTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: () => presentDopamineAuthScreen(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: DopamineTheme.neonGreen,
                              foregroundColor: const Color(0xFF0A0A0A),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                            ),
                            child: Text(l10n.actionLogin),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.92,
                      end: 1,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _newBadgeToast == null
                  ? const SizedBox.shrink()
                  : _buildNewBadgeToast(theme),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ProfileStickyHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _ProfileStickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

final class _ProfileBadgeVm {
  const _ProfileBadgeVm({
    required this.key,
    required this.label,
    required this.assetPath,
    required this.unlocked,
    required this.description,
    required this.requirementText,
  });

  final String key;
  final String label;
  final String assetPath;
  final bool unlocked;
  final String description;
  final String requirementText;
}

/// 계정 영역 — 프로필 사진 카드 (글래스 톤 + 아이콘 액션)
class _AccountProfilePhotoCard extends StatelessWidget {
  const _AccountProfilePhotoCard({
    required this.theme,
    required this.l10n,
    required this.photoUrl,
    required this.profileSaved,
    required this.uploadingPhoto,
    required this.onPickPhoto,
    required this.onRemovePhoto,
    required this.onOpenBadges,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final String? photoUrl;
  final bool profileSaved;
  final bool uploadingPhoto;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback onOpenBadges;

  @override
  Widget build(BuildContext context) {
    final normalizedPhotoUrl = photoUrl?.trim();
    final hasPhoto = profileSaved && normalizedPhotoUrl?.isNotEmpty == true;
    final borderGlow = DopamineTheme.neonGreen.withValues(alpha: 0.35);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.35),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: DopamineTheme.neonGreen.withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: _ProfilePhotoIconAction(
              icon: Icons.emoji_events_rounded,
              tooltip: AppLocalizations.of(context)!.profileBadgeSectionTitle,
              foreground: const Color(0xFFFFC857),
              background: const Color(0xFFFFC857).withValues(alpha: 0.14),
              borderColor: const Color(0xFFFFC857).withValues(alpha: 0.35),
              onPressed: onOpenBadges,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: uploadingPhoto ? null : onPickPhoto,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: DopamineTheme.neonGreen.withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                borderGlow,
                                DopamineTheme.neonGreen.withValues(alpha: 0.12),
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            child: ClipOval(
                              child: _profileAvatarChild(normalizedPhotoUrl),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (uploadingPhoto)
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: DopamineTheme.neonGreen,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ProfilePhotoIconAction(
                    icon: Icons.add_photo_alternate_rounded,
                    tooltip: l10n.profilePhotoTitle,
                    foreground: DopamineTheme.neonGreen,
                    background: DopamineTheme.neonGreen.withValues(alpha: 0.14),
                    borderColor: DopamineTheme.neonGreen.withValues(
                      alpha: 0.35,
                    ),
                    onPressed: uploadingPhoto ? null : onPickPhoto,
                  ),
                  if (hasPhoto) ...[
                    const SizedBox(width: 14),
                    _ProfilePhotoIconAction(
                      icon: Icons.delete_outline_rounded,
                      tooltip: l10n.profilePhotoRemove,
                      foreground: DopamineTheme.accentRed,
                      background: DopamineTheme.accentRed.withValues(
                        alpha: 0.12,
                      ),
                      borderColor: DopamineTheme.accentRed.withValues(
                        alpha: 0.35,
                      ),
                      onPressed: uploadingPhoto ? null : onRemovePhoto,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _profileAvatarChild(String? normalizedPhotoUrl) {
    if (normalizedPhotoUrl != null && normalizedPhotoUrl.isNotEmpty) {
      return Image.network(
        normalizedPhotoUrl,
        key: ValueKey<String>(normalizedPhotoUrl),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        gaplessPlayback: false,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.person_rounded,
          size: 52,
          color: DopamineTheme.textSecondary,
        ),
      );
    }
    return Icon(
      Icons.person_rounded,
      size: 52,
      color: DopamineTheme.textSecondary.withValues(alpha: 0.95),
    );
  }
}

class _ProfilePhotoIconAction extends StatelessWidget {
  const _ProfilePhotoIconAction({
    required this.icon,
    required this.tooltip,
    required this.foreground,
    required this.background,
    required this.borderColor,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: background,
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              icon,
              size: 24,
              color: onPressed == null
                  ? foreground.withValues(alpha: 0.35)
                  : foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.l10n});

  final ProfileStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    void refreshCounts() {
      ProfileStatsStore.instance.refreshWithCurrentFirebaseUser();
    }

    return Row(
      children: [
        Expanded(
          child: _StatCell(
            value: stats.postsCount.toString(),
            label: l10n.profileStatPosts,
            onTap: null,
          ),
        ),
        Expanded(
          child: _StatCell(
            value: stats.followingCount.toString(),
            label: l10n.profileStatFollowing,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FollowListScreen(
                    kind: FollowListKind.following,
                    onListChanged: refreshCounts,
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _StatCell(
            value: stats.followersCount.toString(),
            label: l10n.profileStatFollowers,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const FollowListScreen(kind: FollowListKind.followers),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _StatCell(
            value: stats.blockedCount.toString(),
            label: l10n.profileStatBlocked,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      BlockedUsersScreen(onListChanged: refreshCounts),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: DopamineTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: onTap != null
                ? DopamineTheme.neonGreen
                : DopamineTheme.textSecondary,
            fontWeight: FontWeight.w700,
            decoration: onTap != null ? TextDecoration.underline : null,
          ),
        ),
      ],
    );
    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: child,
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: child,
      ),
    );
  }
}
