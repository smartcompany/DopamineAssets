// Yahoo Finance 차트 URL (외부 브라우저 등 참고용).

Uri? yahooChartPageUri({
  required String assetClass,
  required String symbol,
}) {
  final y = _yahooChartSymbol(assetClass, symbol);
  if (y.isEmpty) return null;
  // 일봉 + 캔들 스타일 요청 (일부 빌드에서만 쿼리 반영; 무시되면 차트 툴바에서 Candle 선택)
  return Uri.https(
    'finance.yahoo.com',
    '/chart/${Uri.encodeComponent(y)}',
    <String, String>{
      'interval': '1d',
      'range': '3mo',
      'chartType': 'candle',
    },
  );
}

/// 서버 `commodity-fx-yahoo`와 동일 — FX 코드로 열릴 때 Yahoo 선물 티커로 연결.
String? _commoditySpotToYahooTicker(String raw) {
  final u = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  const m = <String, String>{
    'XAUUSD': 'GC=F',
    'XAU=X': 'GC=F',
    'XAGUSD': 'SI=F',
    'XAG=X': 'SI=F',
    'XPTUSD': 'PL=F',
    'XPDUSD': 'PA=F',
    'USOIL': 'CL=F',
    'UKOIL': 'BZ=F',
    'WTICOUSD': 'CL=F',
    'BRENTUSD': 'BZ=F',
  };
  return m[u];
}

String _yahooChartSymbol(String assetClass, String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '';
  final spotYahoo = _commoditySpotToYahooTicker(raw);
  if (spotYahoo != null) {
    return spotYahoo;
  }
  final u = t.toUpperCase();
  switch (assetClass) {
    case 'crypto':
      if (u.endsWith('USDT') && u.length > 4) {
        return '${u.substring(0, u.length - 4)}-USD';
      }
      if (u.endsWith('USDC') && u.length > 4) {
        return '${u.substring(0, u.length - 4)}-USD';
      }
      if (t.contains('-')) return t;
      return '$t-USD';
    case 'us_stock':
    case 'kr_stock':
    case 'jp_stock':
    case 'cn_stock':
    case 'commodity':
      return t;
    case 'theme':
      return '';
    default:
      return t;
  }
}
