/// Base URL for the Next.js API (no trailing slash).
/// 로컬 서버 쓸 때: `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000`
/// (Android 에뮬레이터는 `http://10.0.2.2:3000`)
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dopamine-assets-server.vercel.app',
  );

  /// 홈 랭킹 데이터 소스.
  /// - `universe` / `yahoo_us`: 랭킹은 모두 Supabase `dopamine_feed_cache`(GH Actions가 CoinGecko·Yahoo·네이버로 갱신).
  static const String rankingSource = 'yahoo_us';

  /// `true`이면 홈 화면에서 랭킹 API를 주기적으로 폴링한다. `false`면 첫 로드·필터 적용 시만 요청.
  static const bool enableHomeRankingPoll = false;
}
