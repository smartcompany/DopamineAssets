final class MarketSummary {
  const MarketSummary({
    this.kimchiPremiumPct,
    this.usdKrw,
    this.marketStatus,
  });

  final double? kimchiPremiumPct;
  final double? usdKrw;
  final String? marketStatus;

  factory MarketSummary.fromJson(Map<String, dynamic> json) {
    return MarketSummary(
      kimchiPremiumPct: json['kimchiPremiumPct'] == null
          ? null
          : (json['kimchiPremiumPct'] as num).toDouble(),
      usdKrw: json['usdKrw'] == null
          ? null
          : (json['usdKrw'] as num).toDouble(),
      marketStatus: json['marketStatus'] as String?,
    );
  }
}
