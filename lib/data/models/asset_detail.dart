final class AssetDetail {
  const AssetDetail({
    required this.symbol,
    required this.name,
    required this.assetClass,
    required this.sector,
    required this.industry,
    required this.marketCap,
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
