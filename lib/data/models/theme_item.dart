final class ThemeItem {
  const ThemeItem({
    required this.id,
    required this.name,
    required this.avgChangePct,
    required this.volumeLiftPct,
    required this.symbolCount,
    required this.themeScore,
  });

  final String id;
  final String name;
  final double avgChangePct;
  final double volumeLiftPct;
  final int symbolCount;
  final double themeScore;

  factory ThemeItem.fromJson(Map<String, dynamic> json) {
    return ThemeItem(
      id: json['id'] as String,
      name: json['name'] as String,
      avgChangePct: (json['avgChangePct'] as num).toDouble(),
      volumeLiftPct: (json['volumeLiftPct'] as num).toDouble(),
      symbolCount: (json['symbolCount'] as num).toInt(),
      themeScore: (json['themeScore'] as num).toDouble(),
    );
  }
}
