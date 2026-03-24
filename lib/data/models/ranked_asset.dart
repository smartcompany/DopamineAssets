final class RankedAsset {
  const RankedAsset({
    required this.symbol,
    required this.name,
    required this.priceChangePct,
    required this.volumeChangePct,
    required this.dopamineScore,
    this.assetClass,
    this.commodityKind,
    this.summaryLine,
  });

  final String symbol;
  final String name;
  final double priceChangePct;
  final double volumeChangePct;
  final double dopamineScore;
  final String? assetClass;
  final String? commodityKind;
  final String? summaryLine;

  factory RankedAsset.fromJson(Map<String, dynamic> json) {
    return RankedAsset(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      priceChangePct: (json['priceChangePct'] as num).toDouble(),
      volumeChangePct: (json['volumeChangePct'] as num).toDouble(),
      dopamineScore: (json['dopamineScore'] as num).toDouble(),
      assetClass: json['assetClass'] as String?,
      commodityKind: json['commodityKind'] as String?,
      summaryLine: json['summaryLine'] as String?,
    );
  }

  /// 커뮤니티 등에서 상세만 열 때 — 피드 수치는 0으로 둔다.
  factory RankedAsset.communityShell({
    required String symbol,
    required String assetClass,
    String? displayName,
  }) {
    final n = displayName?.trim();
    return RankedAsset(
      symbol: symbol,
      name: n != null && n.isNotEmpty ? n : symbol,
      priceChangePct: 0,
      volumeChangePct: 0,
      dopamineScore: 0,
      assetClass: assetClass,
    );
  }
}
