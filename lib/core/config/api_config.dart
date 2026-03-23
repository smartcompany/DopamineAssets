/// Base URL for the Next.js API (no trailing slash).
/// 로컬 예: http://127.0.0.1:3000 — Android 에뮬레이터는 http://10.0.2.2:3000
abstract final class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:3000';

  /// 홈 랭킹 데이터 소스.
  /// - `universe`: 미국·원자재는 Yahoo 차트, 코인은 Bybit 스팟, 한국은 네이버 증권 급등/급락 HTML.
  /// - `yahoo_us`: Yahoo 미국 + Bybit 코인 + 한국은 위와 동일.
  static const String rankingSource = 'yahoo_us';
}
