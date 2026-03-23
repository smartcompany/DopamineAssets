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
}
