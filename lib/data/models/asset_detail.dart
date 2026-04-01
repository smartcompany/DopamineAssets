final class AssetDetail {
  const AssetDetail({
    required this.symbol,
    required this.name,
    required this.assetClass,
    required this.sector,
    required this.industry,
    required this.marketCap,
    this.marketCapRaw,
    this.marketCapRank,
    this.currentPrice,
    required this.exchange,
    required this.currency,
    required this.description,
    required this.website,
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.dataSources,
    required this.asOf,
    this.commodityKind,
    this.moveSummaryKo,
    this.themeId,
    this.themeSymbols,
  });

  final String symbol;
  final String name;
  final String assetClass;
  final String? commodityKind;
  final String? themeId;
  final List<String>? themeSymbols;
  final String? sector;
  final String? industry;
  final String? marketCap;
  /// 서버 원시 시총 — [currency]와 동일 단위(예: KRW=원). 한국어 UI에서 백만 단위 표기에 사용.
  final double? marketCapRaw;
  /// CoinGecko 시총 순위 (암호화폐). 그 외 null.
  final int? marketCapRank;
  /// CoinGecko USD 현재가 표시 문자열 (암호화폐). 그 외 null.
  final String? currentPrice;
  final String? exchange;
  final String? currency;
  final String? description;
  final String? website;
  final String? baseCurrency;
  final String? quoteCurrency;
  final List<String> dataSources;
  final String asOf;
  final String? moveSummaryKo;

  factory AssetDetail.fromJson(Map<String, dynamic> json) {
    final sources = json['dataSources'];
    final ts = json['themeSymbols'];
    return AssetDetail(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      assetClass: json['assetClass'] as String,
      themeId: json['themeId'] as String?,
      themeSymbols: ts is List<dynamic>
          ? ts.map((e) => e.toString()).toList()
          : null,
      commodityKind: json['commodityKind'] as String?,
      sector: json['sector'] as String?,
      industry: json['industry'] as String?,
      marketCap: json['marketCap'] as String?,
      marketCapRaw: _parseOptionalDouble(json['marketCapRaw']),
      marketCapRank: _parseOptionalInt(json['marketCapRank']),
      currentPrice: json['currentPrice'] as String?,
      exchange: json['exchange'] as String?,
      currency: json['currency'] as String?,
      description: json['description'] as String?,
      website: json['website'] as String?,
      baseCurrency: json['baseCurrency'] as String?,
      quoteCurrency: json['quoteCurrency'] as String?,
      dataSources: sources is List<dynamic>
          ? sources.map((e) => e.toString()).toList()
          : const [],
      asOf: json['asOf'] as String,
      moveSummaryKo: json['moveSummaryKo'] as String?,
    );
  }
}

int? _parseOptionalInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return null;
}

double? _parseOptionalDouble(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  return null;
}
