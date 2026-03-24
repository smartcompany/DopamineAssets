import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:share_lib/share_lib.dart';

import 'dopamine_user.dart';

/// share_lib [AuthProvider]용 — 서버 프로필 API 없이 Firebase 사용자만 반환합니다.
final class DopamineAuthService implements AuthServiceInterface {
  @override
  void setToken(String token) {
    // 토큰은 댓글 POST 시 Firebase에서 직접 가져옵니다.
  }

  @override
  Future<dynamic> getCurrentUser() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return null;
    final name = u.displayName?.trim();
    final email = u.email?.trim();
    final label = (name != null && name.isNotEmpty)
        ? name
        : (email != null && email.isNotEmpty)
            ? email
            : 'User';
    return DopamineUser(uid: u.uid, displayName: label);
  }

  @override
  Future<Map<String, String>> loginWithKakao(String accessToken) async {
    throw UnsupportedError('Kakao login is disabled in Dopamine Assets');
  }
}
