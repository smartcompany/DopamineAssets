import 'package:flutter/foundation.dart';

import '../../data/models/ranked_asset.dart';

/// 홈 상·하위 랭킹에서 가져온 종목명·심볼로 커뮤니티 검색 자동완성에 씁니다.
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

  /// 글쓰기 종목 드롭다운용 (랭킹 로드 후 채워짐).
  List<RankedAsset> get rankedAssets => List.unmodifiable(_rankedAssets);

  List<RankedAsset> assetsForClass(String assetClass) {
    return _rankedAssets.where((a) => a.assetClass == assetClass).toList();
  }

  /// 대소문자 무시 부분 일치. 최대 [limit]개.
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
}
