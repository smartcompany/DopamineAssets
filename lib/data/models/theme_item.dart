final class ThemeItem {
  const ThemeItem({
    required this.id,
    required this.name,
    required this.avgChangePct,
    required this.volumeLiftPct,
    required this.symbolCount,
    required this.themeScore,
    required this.symbols,
    required this.detailSymbol,
    required this.detailAssetClass,
  });

  final String id;
  final String name;
  final double avgChangePct;
  final double volumeLiftPct;
  final int symbolCount;
  final double themeScore;
  /// Yahoo 티커 목록 (뉴스 검색)
  final List<String> symbols;
  /// 종목 상세 진입용 (테마 구성 첫 심볼)
  final String detailSymbol;
  final String detailAssetClass;

  factory ThemeItem.fromJson(Map<String, dynamic> json) {
    final raw = json['symbols'];
    final syms = raw is List<dynamic>
        ? raw.map((e) => e.toString()).toList()
        : const <String>[];
    return ThemeItem(
      id: json['id'] as String,
      name: json['name'] as String,
      avgChangePct: (json['avgChangePct'] as num).toDouble(),
      volumeLiftPct: (json['volumeLiftPct'] as num).toDouble(),
      symbolCount: (json['symbolCount'] as num).toInt(),
      themeScore: (json['themeScore'] as num).toDouble(),
      symbols: syms,
      detailSymbol: json['detailSymbol'] as String? ?? '',
      detailAssetClass: json['detailAssetClass'] as String? ?? 'us_stock',
    );
  }
}
