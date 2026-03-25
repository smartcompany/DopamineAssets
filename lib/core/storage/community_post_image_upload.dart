import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../network/api_exception.dart';

/// Supabase Storage (`dopamine-assets`) — 서버 [POST /api/feed/community-image] 경유.
Future<String> uploadCommunityPostImage({
  required String idToken,
  required List<int> bytes,
  required String filename,
  String contentType = 'image/jpeg',
}) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/api/feed/community-image');
  final request = http.MultipartRequest('POST', uri);
  request.headers['Authorization'] = 'Bearer $idToken';
  MediaType? mediaType;
  try {
    mediaType = MediaType.parse(contentType);
  } catch (_) {
    mediaType = MediaType('image', 'jpeg');
  }
  request.files.add(
    http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: mediaType,
    ),
  );

  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw ApiException('HTTP ${response.statusCode}');
  }
  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    throw ApiException('Invalid upload response');
  }
  final url = decoded['url'] as String?;
  if (url == null || url.isEmpty) {
    throw ApiException('Missing image URL');
  }
  return url;
}
