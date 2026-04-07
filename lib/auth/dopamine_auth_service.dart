import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    if (_token.isEmpty) {
      if (kDebugMode) {
        debugPrint('[AuthService][profile/me] skip: empty token');
      }
      return null;
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/profile/me');
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );
    if (kDebugMode) {
      debugPrint('[AuthService][profile/me] GET $uri status=${response.statusCode}');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (kDebugMode) {
        debugPrint('[AuthService][profile/me] non-2xx -> null');
      }
      return null;
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      if (kDebugMode) {
        debugPrint('[AuthService][profile/me] invalid payload -> null');
      }
      return null;
    }
    final profile = decoded['profile'];
    if (profile == null) {
      if (kDebugMode) {
        debugPrint('[AuthService][profile/me] profile is null');
      }
      return null;
    }
    if (profile is! Map<String, dynamic>) {
      if (kDebugMode) {
        debugPrint('[AuthService][profile/me] profile shape invalid -> null');
      }
      return null;
    }
    final uid = profile['uid'] as String?;
    if (uid == null || uid.isEmpty) {
      if (kDebugMode) {
        debugPrint('[AuthService][profile/me] missing uid -> null');
      }
      return null;
    }
    final displayName = (profile['displayName'] as String?)?.trim() ?? '';
    final rawPhoto = profile['photoUrl'] as String?;
    final photoUrl =
        rawPhoto != null && rawPhoto.trim().isNotEmpty ? rawPhoto.trim() : null;
    final rawSus = profile['suspendedUntil'] as String?;
    final suspendedUntil = rawSus != null && rawSus.trim().isNotEmpty
        ? DateTime.tryParse(rawSus.trim())
        : null;
    if (kDebugMode) {
      debugPrint(
        '[AuthService][profile/me] ok uid=$uid suspendedUntil=${suspendedUntil?.toIso8601String() ?? "null"}',
      );
    }
    return DopamineUser(
      uid: uid,
      displayName: displayName,
      photoUrl: photoUrl,
      suspendedUntil: suspendedUntil,
    );
  }

  @override
  Future<Map<String, String>> loginWithKakao(String accessToken) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/kakao/firebase');
    final response = await http.post(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'access_token': accessToken}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Kakao login failed (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Kakao login failed (invalid response)');
    }
    final uid = (decoded['uid'] as String?)?.trim() ?? '';
    final kakaoId = (decoded['kakao_id'] as String?)?.trim() ?? '';
    final customToken = (decoded['custom_token'] as String?)?.trim() ?? '';
    if (uid.isEmpty || kakaoId.isEmpty || customToken.isEmpty) {
      throw Exception('Kakao login failed (missing token)');
    }
    return {
      'uid': uid,
      'kakao_id': kakaoId,
      'custom_token': customToken,
    };
  }
}
