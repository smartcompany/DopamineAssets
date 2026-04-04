import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../network/api_exception.dart';
import 'upload_limits.dart';

Future<String> _uploadImage({
  required String idToken,
  required List<int> bytes,
  required String filename,
  required String contentType,
  required String scope,
}) async {
  if (bytes.length > kCommunityImageUploadMaxBytes) {
    throw ApiException(
      '파일이 너무 큽니다(최대 ${(kCommunityImageUploadMaxBytes / (1024 * 1024)).round()}MB). '
      'GIF는 다른 것을 선택하거나 첨부 수를 줄여 주세요.',
    );
  }

  final signUri =
      Uri.parse('${ApiConfig.baseUrl}/api/feed/community-image/sign');
  final signRes = await http.post(
    signUri,
    headers: {
      'Authorization': 'Bearer $idToken',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'contentType': contentType,
      'scope': scope,
      'byteLength': bytes.length,
    }),
  );

  if (signRes.statusCode < 200 || signRes.statusCode >= 300) {
    try {
      final err = jsonDecode(signRes.body);
      if (err is Map<String, dynamic> && err['error'] == 'invalid_size') {
        throw ApiException(
          '파일이 너무 큽니다(최대 ${(kCommunityImageUploadMaxBytes / (1024 * 1024)).round()}MB). '
          'GIF는 다른 것을 선택하거나 첨부 수를 줄여 주세요.',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
    }
    throw ApiException('HTTP ${signRes.statusCode}');
  }

  final signJson = jsonDecode(signRes.body) as Map<String, dynamic>;
  final signedUrl = signJson['signedUrl'] as String?;
  final publicUrl = signJson['publicUrl'] as String?;
  if (signedUrl == null ||
      publicUrl == null ||
      signedUrl.isEmpty ||
      publicUrl.isEmpty) {
    throw ApiException('Invalid sign response');
  }

  final putRes = await http.put(
    Uri.parse(signedUrl),
    headers: {'Content-Type': contentType},
    body: bytes,
  );

  if (putRes.statusCode < 200 || putRes.statusCode >= 300) {
    throw ApiException('업로드 실패 (${putRes.statusCode})');
  }

  return publicUrl;
}

/// Supabase Storage — [POST /api/feed/community-image/sign] 후 서명 URL로 직접 PUT.
Future<String> uploadCommunityPostImage({
  required String idToken,
  required List<int> bytes,
  required String filename,
  String contentType = 'image/jpeg',
}) async {
  return _uploadImage(
    idToken: idToken,
    bytes: bytes,
    filename: filename,
    contentType: contentType,
    scope: 'community',
  );
}

/// 프로필 사진 전용. Storage 경로는 `profiles/{uid}/...`.
Future<String> uploadProfileImage({
  required String idToken,
  required List<int> bytes,
  required String filename,
  String contentType = 'image/jpeg',
}) async {
  return _uploadImage(
    idToken: idToken,
    bytes: bytes,
    filename: filename,
    contentType: contentType,
    scope: 'profile',
  );
}
