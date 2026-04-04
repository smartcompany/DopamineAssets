import 'dart:convert';

import 'package:http/http.dart' as http;

import '../giphy/giphy_config.dart';
import 'api_config.dart';

/// 앱 기동 시 [GET /api/settings] 를 한 번 불러 GIPHY 키 등을 메모리에 둡니다.
/// 실패해도 앱은 계속 동작합니다(GIF 피커만 비활성될 수 있음).
Future<void> preloadAppSettings() async {
  try {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/settings');
    final res = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) return;
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) return;
    final raw = decoded['giphy_api_key'];
    if (raw is Map<String, dynamic>) {
      GiphyRuntimeKeys.applyFromSettings(raw);
    }
  } catch (_) {
    // 네트워크/파싱 실패 시 무시
  }
}
