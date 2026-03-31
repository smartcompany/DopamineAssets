import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

final class FavoriteAssetItem {
  const FavoriteAssetItem({
    required this.symbol,
    required this.assetClass,
    required this.name,
  });

  final String symbol;
  final String assetClass;
  final String name;

  String get id => '$assetClass::$symbol';

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'assetClass': assetClass,
        'name': name,
      };

  factory FavoriteAssetItem.fromJson(Map<String, dynamic> json) {
    return FavoriteAssetItem(
      symbol: (json['symbol'] as String? ?? '').trim(),
      assetClass: (json['assetClass'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
    );
  }
}

abstract final class FavoriteAssetsPrefs {
  FavoriteAssetsPrefs._();

  static const _key = 'favorite_assets_v1';

  static Future<List<FavoriteAssetItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const [];
      final out = <FavoriteAssetItem>[];
      for (final e in decoded) {
        if (e is! Map<String, dynamic>) continue;
        final item = FavoriteAssetItem.fromJson(e);
        if (item.symbol.isEmpty || item.assetClass.isEmpty) continue;
        out.add(item);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(List<FavoriteAssetItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<bool> contains({
    required String symbol,
    required String assetClass,
  }) async {
    final items = await load();
    return items.any(
      (e) => e.symbol == symbol && e.assetClass == assetClass,
    );
  }

  static Future<bool> toggle(FavoriteAssetItem item) async {
    final items = await load();
    final idx = items.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      final next = [...items]..removeAt(idx);
      await save(next);
      return false;
    }
    final next = [item, ...items];
    await save(next);
    return true;
  }
}
