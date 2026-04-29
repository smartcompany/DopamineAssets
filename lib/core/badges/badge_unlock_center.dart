import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class BadgeUnlockToast {
  const BadgeUnlockToast({
    required this.badgeKey,
    required this.label,
    required this.assetPath,
  });

  final String badgeKey;
  final String label;
  final String assetPath;
}

final class BadgeUnlockCenter extends ChangeNotifier {
  BadgeUnlockCenter._();
  static final BadgeUnlockCenter instance = BadgeUnlockCenter._();

  static const _kUnlocked = 'badge_unlocked_keys_v1';
  static const _kCounters = 'badge_counters_v1';

  final Set<String> _unlocked = <String>{};
  final Map<String, int> _counters = <String, int>{};
  final Set<String> _marketClasses = <String>{};
  final Set<String> _homeVisitDays = <String>{};

  BadgeUnlockToast? _pendingToast;
  BadgeUnlockToast? get pendingToast => _pendingToast;

  bool _initialized = false;
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
    _initialized = true;
  }

  bool isUnlocked(String key) => _unlocked.contains(key);

  void clearToast() {
    _pendingToast = null;
    notifyListeners();
  }

  Future<void> trackEvent(
    String eventName,
    Map<String, Object> params,
  ) async {
    await ensureInitialized();

    switch (eventName) {
      case 'home_view':
        _increment('home_view_count');
        final day = DateTime.now().toIso8601String().substring(0, 10);
        if (_homeVisitDays.add(day)) {
          _counters['home_unique_days'] = _homeVisitDays.length;
        }
        _unlock('first');
        if ((_counters['home_unique_days'] ?? 0) >= 7) _unlock('visit_7');
        break;
      case 'community_view':
        _increment('community_view_count');
        _unlock('explorer');
        break;
      case 'community_post_submit':
        if (params['is_edit'] == true) break;
        _increment('post_count');
        _unlock('write_first');
        if ((_counters['post_count'] ?? 0) + (_counters['reply_count'] ?? 0) >=
            20) {
          _unlock('talk_king');
        }
        break;
      case 'community_reply_submit':
        _increment('reply_count');
        _unlock('comment_first');
        if ((_counters['post_count'] ?? 0) + (_counters['reply_count'] ?? 0) >=
            20) {
          _unlock('talk_king');
        }
        break;
      case 'favorite_toggled':
        if (params['favored'] == true) {
          _increment('favored_count');
          if ((_counters['favored_count'] ?? 0) >= 3) _unlock('radar_on');
        }
        break;
      case 'asset_detail_open':
        _increment('asset_open_count');
        if ((_counters['asset_open_count'] ?? 0) >= 50) _unlock('scan_assets');
        final ac = (params['asset_class'] ?? '').toString();
        if (ac.isNotEmpty && ac != 'unknown') {
          _marketClasses.add(ac);
          _counters['market_class_count'] = _marketClasses.length;
          if (_marketClasses.length >= 4) _unlock('multi_market');
        }
        break;
      case 'community_like_toggled':
        if (params['liked'] == true) {
          _increment('like_given_count');
          if ((_counters['like_given_count'] ?? 0) >= 100) {
            _unlock('heart_king');
          }
        }
        break;
    }

    final levelScore = (_counters['post_count'] ?? 0) * 12 +
        (_counters['reply_count'] ?? 0) * 6 +
        (_counters['like_given_count'] ?? 0) * 2;
    if (levelScore >= 80) _unlock('level_5');
    if (levelScore >= 220) _unlock('level_10');

    await _persist();
  }

  void _increment(String key) {
    _counters[key] = (_counters[key] ?? 0) + 1;
  }

  void _unlock(String key) {
    if (_unlocked.contains(key)) return;
    _unlocked.add(key);
    _pendingToast = BadgeUnlockToast(
      badgeKey: key,
      label: _badgeMeta[key]?.$1 ?? key,
      assetPath: _badgeMeta[key]?.$2 ?? 'assets/badges/badge_first.jpg',
    );
    notifyListeners();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kUnlocked, _unlocked.toList()..sort());
    await p.setString(_kCounters, jsonEncode(_counters));
  }
}

const Map<String, (String, String)> _badgeMeta = {
  'first': ('첫걸음', 'assets/badges/badge_first.jpg'),
  'explorer': ('커뮤니티 탐험가', 'assets/badges/badge_explorer.jpg'),
  'write_first': ('첫 작성자', 'assets/badges/badge_write_first.jpg'),
  'comment_first': ('첫 댓글러', 'assets/badges/badge_comment_first.jpg'),
  'radar_on': ('레이더 ON', 'assets/badges/badge_rader_on.jpg'),
  'scan_assets': ('스캐너', 'assets/badges/badge_scan_assets.jpg'),
  'talk_king': ('토론가', 'assets/badges/badge_talk_king.jpg'),
  'heart_king': ('공감왕', 'assets/badges/badge_hart_king.jpg'),
  'visit_7': ('연속 7일', 'assets/badges/badge_visit_7.jpg'),
  'level_5': ('레벨 5', 'assets/badges/badge_5_level.jpg'),
  'level_10': ('레벨 10', 'assets/badges/badge_level_10.jpg'),
  'multi_market': ('멀티마켓', 'assets/badges/badge_multi_market.jpg'),
};
