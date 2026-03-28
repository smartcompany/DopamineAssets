import 'dart:convert';

import 'package:flutter/services.dart';

/// LetsMeet `validate-banned-words.ts` 와 동일한 부분 문자열 매칭.
/// `assets/banned_words.json` 은 `server/src/lib/banned-words.json` 과 동기화.
abstract final class UgcBannedWords {
  UgcBannedWords._();

  static List<String>? _words;

  static Future<void> preload() async {
    if (_words != null) return;
    final raw = await rootBundle.loadString('assets/banned_words.json');
    final decoded = jsonDecode(raw);
    if (decoded is List<dynamic>) {
      _words = decoded.map((e) => e.toString()).toList();
    } else {
      _words = [];
    }
  }

  /// 로드 전이면 null (차단 안 함). [preload] 후 사용.
  static String? firstMatch(String text) {
    final list = _words;
    if (list == null) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    for (final word in list) {
      final w = word.trim();
      if (w.isEmpty) continue;
      if (lower.contains(w.toLowerCase())) return w;
    }
    return null;
  }
}
