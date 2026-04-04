import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// 서버 [GET /api/settings] 의 `giphy_api_key` 만 사용합니다. [preloadAppSettings] 로 채웁니다.
abstract final class GiphyRuntimeKeys {
  static String? ios;
  static String? android;
  static String? web;

  static void applyFromSettings(Map<String, dynamic> raw) {
    ios = _read(raw['ios']);
    android = _read(raw['android']);
    web = _read(raw['web']);
  }

  static String? _read(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}

String? giphyApiKeyForPlatform() {
  if (kIsWeb) {
    final k = GiphyRuntimeKeys.web?.trim();
    return (k == null || k.isEmpty) ? null : k;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      final k = GiphyRuntimeKeys.ios?.trim();
      return (k == null || k.isEmpty) ? null : k;
    case TargetPlatform.android:
      final k = GiphyRuntimeKeys.android?.trim();
      return (k == null || k.isEmpty) ? null : k;
    default:
      final a = GiphyRuntimeKeys.ios?.trim();
      if (a != null && a.isNotEmpty) return a;
      final b = GiphyRuntimeKeys.android?.trim();
      if (b != null && b.isNotEmpty) return b;
      return null;
  }
}

bool get giphyPickerAvailable {
  final k = giphyApiKeyForPlatform();
  return k != null && k.isNotEmpty;
}
