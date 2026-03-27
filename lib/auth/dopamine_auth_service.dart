import 'dart:convert';

import 'package:share_lib/share_lib.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import 'dopamine_user.dart';

/// share_lib [AuthProvider]용 — 서버 프로필 API에서 사용자 정보를 가져옵니다.
final class DopamineAuthService implements AuthServiceInterface {
  String _token = '';

  @override
  void setToken(String token) {
    _token = token;
  }

  @override
  Future<dynamic> getCurrentUser() async {
    if (_token.isEmpty) return null;
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/profile/me');
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    final profile = decoded['profile'];
    if (profile is! Map<String, dynamic>) {
      return null;
    }
    final uid = profile['uid'] as String?;
    final displayName = profile['displayName'] as String?;
    if (uid == null || uid.isEmpty || displayName == null || displayName.isEmpty) {
      return null;
    }
    final photoUrl = profile['photoUrl'] as String?;
    return DopamineUser(
      uid: uid,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  @override
  Future<Map<String, String>> loginWithKakao(String accessToken) async {
    throw UnsupportedError('Kakao login is disabled in Dopamine Assets');
  }
}
