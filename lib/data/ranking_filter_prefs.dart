import 'package:shared_preferences/shared_preferences.dart';

/// 서버 `include` 쿼리와 동일한 자산군 키 (`feed-query.ts` 의 AssetClass).
abstract final class RankingFilterPrefs {
  RankingFilterPrefs._();

  static const String _key = 'ranking_include_asset_classes';

  static const Set<String> allKeys = {
    'us_stock',
    'kr_stock',
    'crypto',
    'commodity',
  };

  /// UI 표시 순서 (`allKeys`에 항목을 추가할 때 여기에도 같은 키를 넣어 주세요).
  static const List<String> orderedKeys = [
    'us_stock',
    'kr_stock',
    'crypto',
    'commodity',
  ];

  /// 저장값이 없으면 네 가지 모두 선택(기본).
  static Future<Set<String>> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s == null || s.trim().isEmpty) {
      return Set<String>.from(allKeys);
    }
    final parts = s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final valid = parts.intersection(allKeys);
    if (valid.isEmpty) {
      return Set<String>.from(allKeys);
    }
    return valid;
  }

  static Future<void> save(Set<String> classes) async {
    final filtered = classes.intersection(allKeys);
    if (filtered.isEmpty) {
      throw ArgumentError('include_asset_classes_empty');
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, filtered.join(','));
  }
}
