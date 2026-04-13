import 'package:flutter/foundation.dart';

import '../../data/models/interest_surge_item.dart';
import '../../data/models/ranked_asset.dart';

/// 홈 상·하위 랭킹 + 관심 폭주(interest-surge) 종목으로 커뮤니티 글쓰기 심볼·자산군 제안을 채웁니다.
class HomeAssetSuggestions extends ChangeNotifier {
  final List<String> _labels = [];
  final Set<String> _seen = {};
  final List<RankedAsset> _rankedAssets = [];

  void setFromRankings(List<RankedAsset> up, List<RankedAsset> down) {
    _labels.clear();
    _seen.clear();
    _rankedAssets.clear();
    final seenPair = <String>{};

    void addAsset(RankedAsset a) {
      final ac = a.assetClass?.trim();
      if (ac == null || ac.isEmpty) return;
      final sym = a.symbol.trim();
      if (sym.isEmpty) return;
      final key = '$sym|$ac';
      if (seenPair.contains(key)) return;
      seenPair.add(key);
      _rankedAssets.add(
        RankedAsset(
          symbol: sym,
          name: a.name.trim().isEmpty ? sym : a.name.trim(),
          priceChangePct: a.priceChangePct,
          volumeChangePct: a.volumeChangePct,
          dopamineScore: a.dopamineScore,
          assetClass: ac,
          commodityKind: a.commodityKind,
          summaryLine: a.summaryLine,
          coingeckoId: a.coingeckoId,
        ),
      );
    }

    void addLabel(RankedAsset a) {
      final n = a.name.trim();
      if (n.isNotEmpty && !_seen.contains(n)) {
        _seen.add(n);
        _labels.add(n);
      }
      final s = a.symbol.trim();
      if (s.isNotEmpty && !_seen.contains(s)) {
        _seen.add(s);
        _labels.add(s);
      }
    }

    for (final a in up) {
      addAsset(a);
      addLabel(a);
    }
    for (final a in down) {
      addAsset(a);
      addLabel(a);
    }
    _rankedAssets.sort((a, b) {
      final c = a.symbol.compareTo(b.symbol);
      if (c != 0) return c;
      return (a.assetClass ?? '').compareTo(b.assetClass ?? '');
    });
    notifyListeners();
  }

  static const _mergeableInterestClasses = <String>{
    'us_stock',
    'kr_stock',
    'jp_stock',
    'cn_stock',
    'crypto',
    'commodity',
  };

  /// `dopamine_interest_asset_scores` 기반 관심 폭주 목록 — 랭킹과 동일 `(symbol|assetClass)` 는 제외.
  void mergeInterestSurgeItems(List<InterestSurgeItem> items) {
    if (items.isEmpty) return;
    final seenPair = <String>{
      for (final a in _rankedAssets)
        '${a.symbol.trim()}|${a.assetClass?.trim() ?? ''}',
    };

    for (final item in items) {
      final ac = item.category.trim();
      if (!_mergeableInterestClasses.contains(ac)) continue;
      final sym = item.symbol.trim();
      if (sym.isEmpty) continue;
      final key = '$sym|$ac';
      if (seenPair.contains(key)) continue;
      seenPair.add(key);

      final name = item.name.trim().isEmpty ? sym : item.name.trim();
      _rankedAssets.add(
        RankedAsset(
          symbol: sym,
          name: name,
          priceChangePct: 0,
          volumeChangePct: 0,
          dopamineScore: 0,
          assetClass: ac,
        ),
      );

      if (name.isNotEmpty && !_seen.contains(name)) {
        _seen.add(name);
        _labels.add(name);
      }
      if (!_seen.contains(sym)) {
        _seen.add(sym);
        _labels.add(sym);
      }
    }

    _rankedAssets.sort((a, b) {
      final c = a.symbol.compareTo(b.symbol);
      if (c != 0) return c;
      return (a.assetClass ?? '').compareTo(b.assetClass ?? '');
    });
    notifyListeners();
  }

  /// 글쓰기 종목 드롭다운용 (랭킹 로드 후 채워짐).
  List<RankedAsset> get rankedAssets => List.unmodifiable(_rankedAssets);

  List<RankedAsset> assetsForClass(String assetClass) {
    return _rankedAssets.where((a) => a.assetClass == assetClass).toList();
  }

  /// 대소문자 무시 부분 일치(라벨 문자열). 최대 [limit]개.
  List<String> matching(String query, {int limit = 12}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final prefix = <String>[];
    final rest = <String>[];
    for (final label in _labels) {
      final lower = label.toLowerCase();
      if (!lower.contains(q)) continue;
      if (lower.startsWith(q)) {
        prefix.add(label);
      } else {
        rest.add(label);
      }
    }
    prefix.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    rest.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final merged = [...prefix, ...rest];
    if (merged.length <= limit) return merged;
    return merged.sublist(0, limit);
  }

  /// 심볼·종목명 기준 검색. 커뮤니티 검색 자동완성용. 최대 [limit]개.
  List<RankedAsset> matchingAssets(String query, {int limit = 12}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    int score(RankedAsset a) {
      final sym = a.symbol.toLowerCase();
      final name = a.name.toLowerCase();
      if (sym.startsWith(q)) return 0;
      if (name.startsWith(q)) return 1;
      if (sym.contains(q)) return 2;
      if (name.contains(q)) return 3;
      return 100;
    }

    final scored = _rankedAssets.where((a) {
      final sym = a.symbol.toLowerCase();
      final name = a.name.toLowerCase();
      return sym.contains(q) || name.contains(q);
    }).toList();

    scored.sort((a, b) {
      final sa = score(a);
      final sb = score(b);
      if (sa != sb) return sa.compareTo(sb);
      final c = a.symbol.compareTo(b.symbol);
      if (c != 0) return c;
      return (a.assetClass ?? '').compareTo(b.assetClass ?? '');
    });

    if (scored.length <= limit) return scored;
    return scored.sublist(0, limit);
  }
}
