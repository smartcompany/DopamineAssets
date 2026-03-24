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

String _yahooChartSymbol(String assetClass, String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '';
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
    case 'commodity':
    default:
      return t;
  }
}
