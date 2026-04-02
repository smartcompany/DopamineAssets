final class FavoriteAssetItem {
  const FavoriteAssetItem({
    required this.symbol,
    required this.assetClass,
    required this.name,
  });

  final String symbol;
  final String assetClass;
  final String name;

  String get id => '$assetClass::$symbol';

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'assetClass': assetClass,
        'name': name,
      };

  factory FavoriteAssetItem.fromJson(Map<String, dynamic> json) {
    return FavoriteAssetItem(
      symbol: (json['symbol'] as String? ?? '').trim(),
      assetClass: (json['assetClass'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
    );
  }
}
