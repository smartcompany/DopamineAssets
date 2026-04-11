import 'theme_item.dart';

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
    this.themeId,
    this.themeSymbols,
    /// 서버 `RankedAssetDto.id` — CoinGecko coin id (차트 `?id=`).
    this.coingeckoId,
  });

  final String symbol;
  final String name;
  final double priceChangePct;
  final double volumeChangePct;
  final double dopamineScore;
  final String? assetClass;
  final String? commodityKind;
  final String? summaryLine;
  /// [assetClass] == `theme` 일 때 서버 테마 id (차트·상세 API).
  final String? themeId;
  /// 테마 구성 Yahoo 티커 — 뉴스 검색용.
  final List<String>? themeSymbols;
  final String? coingeckoId;

  factory RankedAsset.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    return RankedAsset(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      priceChangePct: (json['priceChangePct'] as num).toDouble(),
      volumeChangePct: (json['volumeChangePct'] as num).toDouble(),
      dopamineScore: (json['dopamineScore'] as num).toDouble(),
      assetClass: json['assetClass'] as String?,
      commodityKind: json['commodityKind'] as String?,
      summaryLine: json['summaryLine'] as String?,
      themeId: json['themeId'] as String?,
      themeSymbols: null,
      coingeckoId: idRaw is String && idRaw.trim().isNotEmpty ? idRaw.trim() : null,
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

  /// 홈/테마 목록의 [ThemeItem] → 종목 상세 UI와 동일 화면.
  factory RankedAsset.fromThemeItem(ThemeItem item) {
    return RankedAsset(
      symbol: item.name,
      name: item.name,
      priceChangePct: item.avgChangePct,
      volumeChangePct: item.volumeLiftPct,
      dopamineScore: item.themeScore,
      assetClass: 'theme',
      themeId: item.id,
      themeSymbols: item.symbols,
    );
  }
}
