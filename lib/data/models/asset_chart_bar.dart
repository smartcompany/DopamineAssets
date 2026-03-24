final class AssetChartBar {
  const AssetChartBar({
    required this.t,
    required this.o,
    required this.h,
    required this.l,
    required this.c,
    required this.v,
  });

  /// Unix seconds (UTC bar open).
  final int t;
  final double o;
  final double h;
  final double l;
  final double c;
  final double v;

  factory AssetChartBar.fromJson(Map<String, dynamic> json) {
    return AssetChartBar(
      t: (json['t'] as num).toInt(),
      o: (json['o'] as num).toDouble(),
      h: (json['h'] as num).toDouble(),
      l: (json['l'] as num).toDouble(),
      c: (json['c'] as num).toDouble(),
      v: (json['v'] as num).toDouble(),
    );
  }
}
