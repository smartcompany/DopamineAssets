import 'package:shared_preferences/shared_preferences.dart';

/// 서버 `include` 쿼리와 동일한 자산군 키 (`feed-query.ts` 의 AssetClass).
abstract final class RankingFilterPrefs {
  RankingFilterPrefs._();

  static const String _key = 'ranking_include_asset_classes';

  static const Set<String> allKeys = {
    'us_stock',
    'kr_stock',
    'jp_stock',
    'cn_stock',
    'crypto',
    'commodity',
  };

  static const List<String> _baseOrder = [
    'us_stock',
    'kr_stock',
    'jp_stock',
    'cn_stock',
    'crypto',
    'commodity',
  ];

  static String _lang2(String? locale) {
    final l = (locale ?? '').trim().toLowerCase();
    if (l.isEmpty) return '';
    final i = l.indexOf(RegExp(r'[-_]'));
    final head = i >= 0 ? l.substring(0, i) : l;
    return head;
  }

  /// i18n 언어별 "기본 선택" (저장값이 없을 때만 사용).
  static Set<String> defaultSelectionForLocale(String? locale) {
    switch (_lang2(locale)) {
      case 'ko':
        return {'us_stock', 'kr_stock', 'crypto', 'commodity'};
      case 'zh':
        return {'us_stock', 'cn_stock', 'crypto', 'commodity'};
      case 'ja':
        return {'us_stock', 'jp_stock', 'crypto', 'commodity'};
      default:
        return {'us_stock', 'crypto', 'commodity'};
    }
  }

  /// i18n 언어별 표시 순서.
  static List<String> orderedKeysForLocale(String? locale) {
    final first = defaultSelectionForLocale(locale).toList();
    final out = <String>[...first];
    for (final k in _baseOrder) {
      if (!out.contains(k)) out.add(k);
    }
    return out;
  }

  /// 저장값이 없으면 [locale] 기본 선택을 사용.
  static Future<Set<String>> load({String? locale}) async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s == null || s.trim().isEmpty) {
      return defaultSelectionForLocale(locale);
    }
    final parts = s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final valid = parts.intersection(allKeys);
    if (valid.isEmpty) {
      return defaultSelectionForLocale(locale);
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
