import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import 'dopamine_user.dart';
import 'present_dopamine_auth_screen.dart';

bool dopamineDisplayNameReady(AuthProvider<DopamineUser> auth) {
  final n = auth.userProfile?.displayName.trim() ?? '';
  return n.isNotEmpty;
}

/// 커뮤니티 글·댓글·좋아요 등: 로그인 + 서버 프로필 닉네임이 있을 때만 true.
///
/// [showLoginHintSnack] 이 true이면 비로그인 시 [AppLocalizations.communityLikeLogin] 스낵바를 띄운 뒤 로그인 화면을 엽니다.
Future<bool> ensureCommunityIdentity(
  BuildContext context, {
  bool showLoginHintSnack = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  var auth = context.read<AuthProvider<DopamineUser>>();
  if (!auth.isLoggedIn()) {
    if (showLoginHintSnack) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityLikeLogin)),
      );
    }
    final ok = await presentDopamineAuthScreen(context);
    if (!context.mounted || !ok) return false;
    auth = context.read<AuthProvider<DopamineUser>>();
    if (!auth.isLoggedIn()) return false;
  }
  if (!dopamineDisplayNameReady(auth)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileNicknameRequiredForCommunity)),
      );
    }
    return false;
  }
  return true;
}
