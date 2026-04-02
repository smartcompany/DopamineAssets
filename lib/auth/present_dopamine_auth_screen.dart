import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import '../features/legal/privacy_processing_consent.dart';
import 'dopamine_auth_config.dart';
import 'dopamine_user.dart';

/// 로그인에 성공하고(필요 시 개인정보 처리 동의까지 완료하면) `true`,
/// 취소·실패·동의 거절(이 경우 로그아웃)이면 `false`.
///
/// 인증 화면 닫기는 share_lib [AuthScreen] 내부의 `Navigator.pop`으로 처리됩니다.
Future<bool> presentDopamineAuthScreen(BuildContext context) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      fullscreenDialog: true,
      builder: (_) => AuthScreen<DopamineUser>(
        config: dopamineAuthConfig(),
      ),
    ),
  );
  if (result != true) return false;
  if (!context.mounted) return false;
  if (await isPrivacyProcessingConsentAccepted()) return true;
  if (!context.mounted) return false;
  final ok = await ensurePrivacyProcessingConsent(context);
  if (!context.mounted) return false;
  if (ok) return true;
  await context.read<AuthProvider<DopamineUser>>().logout();
  return false;
}
