// 거래소/브로커 외부 페이지 URL 빌더.
// 현재 정책:
// - crypto => CoinMarketCap
// - us_stock/kr_stock => ko 로케일은 Toss, 그 외는 Yahoo Finance
// - commodity => Yahoo Finance
// - 그 외 => null

Uri? exchangeViewUri({
  required String localeLanguageCode,
  required String assetClass,
  required String symbol,
  String? cryptoSlug,
}) {
  final lang = localeLanguageCode.trim().toLowerCase();
  final ac = assetClass.trim().toLowerCase();
  if (ac == 'crypto') {
    return coinMarketCapCryptoUri(slug: cryptoSlug);
  }
  if (ac == 'us_stock' || ac == 'kr_stock') {
    if (lang == 'ko') {
      return tossInvestStockOrderUri(assetClass: ac, symbol: symbol);
    }
    return yahooFinanceStockUri(symbol);
  }
  if (ac == 'jp_stock') {
    return yahooJapanStockUri(symbol);
  }
  if (ac == 'cn_stock') {
    return eastMoneyStockUri(symbol);
  }
  if (ac == 'commodity') {
    return yahooFinanceStockUri(symbol);
  }
  return null;
}

/// "거래소에서 보기" 라벨에 들어갈 거래소/서비스 브랜드명.
/// [exchangeViewUri]가 null이면 이 함수도 null을 반환한다.
String? exchangeDisplayName({
  required String localeLanguageCode,
  required String assetClass,
}) {
  final lang = localeLanguageCode.trim().toLowerCase();
  final ac = assetClass.trim().toLowerCase();
  if (ac == 'crypto') {
    return 'CoinMarketCap';
  }
  if (ac == 'us_stock' || ac == 'kr_stock') {
    if (lang == 'ko') {
      return '토스';
    }
    return 'Yahoo Finance';
  }
  if (ac == 'jp_stock') {
    return lang == 'ja' ? 'Yahoo!ファイナンス' : 'Yahoo! Japan';
  }
  if (ac == 'cn_stock') {
    return lang == 'zh' ? '东方财富' : 'Eastmoney';
  }
  if (ac == 'commodity') {
    return 'Yahoo Finance';
  }
  return null;
}

Uri? yahooFinanceStockUri(String symbol) {
  final s = symbol.trim().toUpperCase();
  if (s.isEmpty) return null;
  return Uri.https('finance.yahoo.com', '/quote/$s');
}

/// 일본 주식: Yahoo Finance Japan 종목 페이지.
/// 입력 예: `7203.T` -> `https://finance.yahoo.co.jp/quote/7203.T`
Uri? yahooJapanStockUri(String symbol) {
  final m = RegExp(r'^(\d{1,5})(?:\.(T|JP))?$', caseSensitive: false)
      .firstMatch(symbol.trim());
  if (m == null) return null;
  final code = m.group(1)!.padLeft(4, '0');
  return Uri.https('finance.yahoo.co.jp', '/quote/$code.T');
}

/// 중국 주식: Eastmoney 종목 페이지.
/// - `600519.SS` -> `https://quote.eastmoney.com/sh600519.html`
/// - `000001.SZ` -> `https://quote.eastmoney.com/sz000001.html`
Uri? eastMoneyStockUri(String symbol) {
  final u = symbol.trim().toUpperCase();
  if (u.isEmpty) return null;
  String? market;
  String? code;
  final m = RegExp(r'^(\d{6})\.(SS|SH|SZ)$').firstMatch(u);
  if (m != null) {
    code = m.group(1)!;
    final ex = m.group(2)!;
    market = (ex == 'SZ') ? 'sz' : 'sh';
  } else if (RegExp(r'^\d{6}$').hasMatch(u)) {
    code = u;
    market = (u.startsWith('6')) ? 'sh' : 'sz';
  }
  if (code == null || market == null) return null;
  return Uri.https('quote.eastmoney.com', '/$market$code.html');
}

/// CoinMarketCap 코인 URL.
/// - id(slug) 기반만 허용 (`/currencies/{slug}/`)
Uri? coinMarketCapCryptoUri({
  String? slug,
}) {
  final g = _toCoinMarketCapSlug(slug);
  if (g == null || g.isEmpty) return null;
  return Uri(
    scheme: 'https',
    host: 'coinmarketcap.com',
    pathSegments: <String>['currencies', g, ''],
  );
}

String? _toCoinMarketCapSlug(String? coingeckoId) {
  final raw = coingeckoId?.trim().toLowerCase();
  if (raw == null || raw.isEmpty) return null;
  // CoinGecko id -> CoinMarketCap slug 예외 매핑
  const overrides = <String, String>{
    'siren-2': 'siren',
  };
  return overrides[raw] ?? raw;
}

/// 미국·한국 주식만 지원. 그 외 [assetClass]는 null.
Uri? tossInvestStockOrderUri({
  required String assetClass,
  required String symbol,
}) {
  switch (assetClass.trim().toLowerCase()) {
    case 'us_stock':
      final t = _tossUsTicker(symbol);
      if (t == null || t.isEmpty) return null;
      return Uri(
        scheme: 'https',
        host: 'tossinvest.com',
        pathSegments: <String>['stocks', t, 'order'],
      );
    case 'kr_stock':
      final seg = _tossKrStockPathSegment(symbol);
      if (seg == null || seg.isEmpty) return null;
      return Uri(
        scheme: 'https',
        host: 'tossinvest.com',
        pathSegments: <String>['stocks', seg, 'order'],
      );
    default:
      return null;
  }
}

String? _tossUsTicker(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  s = s.toUpperCase();
  // Yahoo 등에서 쓰는 점 구분(예: BRK.B)은 티커 하이픈 형태로 맞춤.
  s = s.replaceAll('.', '-');
  if (!RegExp(r'^[A-Z0-9^=-]+$').hasMatch(s)) return null;
  return s;
}

/// 토스 한국 종목 경로: `A` + 6자리 종목코드 (예: A005930).
String? _tossKrStockPathSegment(String raw) {
  final u = raw.trim().toUpperCase();
  if (u.isEmpty) return null;
  if (RegExp(r'^A\d{6}$').hasMatch(u)) return u;
  final yahoo = RegExp(r'^(\d{1,6})\.(KS|KQ)$').firstMatch(u);
  if (yahoo != null) {
    return 'A${yahoo.group(1)!.padLeft(6, '0')}';
  }
  if (RegExp(r'^\d{1,6}$').hasMatch(u)) {
    return 'A${u.padLeft(6, '0')}';
  }
  return null;
}
