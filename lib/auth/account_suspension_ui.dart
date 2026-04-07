import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import 'package:dopamine_assets/l10n/app_localizations.dart';

import '../core/network/dopamine_api.dart';
import 'dopamine_user.dart';

bool isDopamineUserSuspended(DopamineUser? user) =>
    user?.isAccountSuspended ?? false;

void showAccountSuspendedSnackBar(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.accountSuspendedSnack)),
  );
}

/// 서버 상태를 다시 확인해 정지 여부를 즉시 반영합니다.
Future<bool> ensureNotSuspendedWithRefresh(BuildContext context) async {
  final auth = context.read<AuthProvider<DopamineUser>>();
  if (!auth.isLoggedIn()) return true;

  DopamineUser? latest = auth.userProfile;
  final token = await auth.getIdToken();
  if (token != null && token.isNotEmpty) {
    try {
      final me = await DopamineApi.fetchProfileMe(idToken: token);
      if (me != null) {
        latest = me;
        auth.setUserProfile(me);
      }
    } catch (_) {
      // 네트워크 오류 시 마지막 로컬 프로필 상태를 사용합니다.
    }
  }

  if (isDopamineUserSuspended(latest)) {
    showAccountSuspendedSnackBar(context);
    return false;
  }
  return true;
}
