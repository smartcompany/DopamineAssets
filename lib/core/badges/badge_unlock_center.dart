import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../network/dopamine_api.dart';

final class BadgeUnlockToast {
  const BadgeUnlockToast({
    required this.badgeKey,
    required this.label,
    required this.imagePath,
  });

  final String badgeKey;
  final String label;
  final String imagePath;
}

final class BadgeUnlockCenter extends ChangeNotifier {
  BadgeUnlockCenter._();
  static final BadgeUnlockCenter instance = BadgeUnlockCenter._();

  static const _kUnlocked = 'badge_unlocked_keys_v1';
  static const _kCounters = 'badge_counters_v1';
  static const _kCatalog = 'badge_catalog_v1';

  final Set<String> _unlocked = <String>{};
  final Map<String, int> _counters = <String, int>{};
  final Map<String, _BadgeCatalogMeta> _catalog = <String, _BadgeCatalogMeta>{};

  BadgeUnlockToast? _pendingToast;
  BadgeUnlockToast? get pendingToast => _pendingToast;

  bool _initialized = false;
  Future<String?> Function()? _idTokenProvider;

  void registerIdTokenProvider(Future<String?> Function() provider) {
    _idTokenProvider = provider;
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    final p = await SharedPreferences.getInstance();
    _unlocked.addAll(p.getStringList(_kUnlocked) ?? const <String>[]);
    final raw = p.getString(_kCounters);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          for (final e in decoded.entries) {
            final v = e.value;
            if (v is num) _counters[e.key] = v.toInt();
          }
        }
      } catch (_) {}
    }
    final rawCatalog = p.getString(_kCatalog);
    if (rawCatalog != null && rawCatalog.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCatalog);
        if (decoded is List) {
          for (final row in decoded) {
            if (row is! Map) continue;
            final key = (row['key'] as String? ?? '').trim();
            final label = (row['label'] as String? ?? '').trim();
            final imagePath = (row['imagePath'] as String? ?? '').trim();
            if (key.isEmpty || imagePath.isEmpty) continue;
            if (!_isRemoteBadgeUrl(imagePath)) continue;
            _catalog[key] = _BadgeCatalogMeta(
              label: label.isEmpty ? key : label,
              imagePath: imagePath,
            );
          }
        }
      } catch (_) {}
    }
    _initialized = true;
    await _bootstrapFromServer();
  }

  bool isUnlocked(String key) => _unlocked.contains(key);
  /// 서버 카탈로그에만 존재. 없으면 빈 문자열.
  String imageFor(String key) => _catalog[key]?.imagePath ?? '';
  String labelFor(String key) => _catalog[key]?.label ?? key;

  void clearToast() {
    _pendingToast = null;
    notifyListeners();
  }

  Future<void> trackEvent(
    String eventName,
    Map<String, Object> params,
  ) async {
    await ensureInitialized();
    final token = await _idTokenProvider?.call();
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      final response = await DopamineApi.postBadgeEvent(
        idToken: token,
        eventName: eventName,
        params: params,
      );
      _applyServerState(
        unlockedKeys: response.unlockedKeys,
        counters: response.counters,
        catalog: response.catalog,
      );
      if (response.newlyUnlocked.isNotEmpty) {
        final badgeKey = response.newlyUnlocked.first;
        _pendingToast = BadgeUnlockToast(
          badgeKey: badgeKey,
          label: labelFor(badgeKey),
          imagePath: imageFor(badgeKey),
        );
      }
      await _persist();
      notifyListeners();
    } catch (e, st) {
      debugPrint('[badges] postBadgeEvent failed: $e\n$st');
    }
  }

  Future<void> _bootstrapFromServer() async {
    try {
      final catalog = await DopamineApi.fetchBadgeCatalog();
      _applyCatalog(catalog.catalog);
    } catch (_) {}
    final token = await _idTokenProvider?.call();
    if (token == null || token.isEmpty) {
      await _persist();
      notifyListeners();
      return;
    }
    try {
      final state = await DopamineApi.fetchMyBadges(idToken: token);
      _applyServerState(
        unlockedKeys: state.unlockedKeys,
        counters: state.counters,
        catalog: state.catalog,
      );
      await _persist();
    } catch (_) {
      await _persist();
    }
    notifyListeners();
  }

  bool _isRemoteBadgeUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  void _applyServerState({
    required Set<String> unlockedKeys,
    required Map<String, int> counters,
    required List<BadgeCatalogItem> catalog,
  }) {
    _unlocked
      ..clear()
      ..addAll(unlockedKeys);
    _counters
      ..clear()
      ..addAll(counters);
    _applyCatalog(catalog);
  }

  void _applyCatalog(List<BadgeCatalogItem> list) {
    if (list.isEmpty) return;
    _catalog.clear();
    for (final item in list) {
      if (item.key.isEmpty) continue;
      final path = _resolveImagePath(item.imageUrl);
      if (path.isEmpty) continue;
      _catalog[item.key] = _BadgeCatalogMeta(
        label: item.label.isEmpty ? item.key : item.label,
        imagePath: path,
      );
    }
  }

  /// 상대경로(`/badges/...`)는 API 베이스 URL 기준으로 절대 URL만 반환한다.
  String _resolveImagePath(String value) {
    final v = value.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    if (v.startsWith('/')) {
      final base = Uri.parse(ApiConfig.baseUrl);
      return base.resolve(v).toString();
    }
    return '';
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kUnlocked, _unlocked.toList()..sort());
    await p.setString(_kCounters, jsonEncode(_counters));
    await p.setString(
      _kCatalog,
      jsonEncode([
        for (final e in _catalog.entries)
          if (_isRemoteBadgeUrl(e.value.imagePath))
            {
              'key': e.key,
              'label': e.value.label,
              'imagePath': e.value.imagePath,
            },
      ]),
    );
  }
}

final class _BadgeCatalogMeta {
  const _BadgeCatalogMeta({required this.label, required this.imagePath});

  final String label;
  final String imagePath;
}
