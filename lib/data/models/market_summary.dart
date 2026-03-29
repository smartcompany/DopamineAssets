final class MarketSummary {
  const MarketSummary({
    this.briefing,
    this.briefingEn,
    this.attribution,
    this.attributionEn,
    this.kimchiPremiumPct,
    this.usdKrw,
    this.marketStatus,
  });

  /// 한국어 시장 요약 본문
  final String? briefing;
  final String? briefingEn;
  final String? attribution;
  final String? attributionEn;
  final double? kimchiPremiumPct;
  final double? usdKrw;
  /// 구 API 호환
  final String? marketStatus;

  String bodyForLanguageCode(String languageCode) {
    final ko = languageCode.toLowerCase().startsWith('ko');
    final primary = ko ? briefing : briefingEn;
    final secondary = ko ? briefingEn : briefing;
    final fromNew = _nonEmpty(primary) ?? _nonEmpty(secondary);
    if (fromNew != null) return fromNew;
    return _nonEmpty(marketStatus) ?? '';
  }

  String? attributionForLanguageCode(String languageCode) {
    final ko = languageCode.toLowerCase().startsWith('ko');
    final primary = ko ? attribution : attributionEn;
    final secondary = ko ? attributionEn : attribution;
    return _nonEmpty(primary) ?? _nonEmpty(secondary);
  }

  static String? _nonEmpty(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  factory MarketSummary.fromJson(Map<String, dynamic> json) {
    return MarketSummary(
      briefing: json['briefing'] as String?,
      briefingEn: json['briefingEn'] as String?,
      attribution: json['attribution'] as String?,
      attributionEn: json['attributionEn'] as String?,
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
