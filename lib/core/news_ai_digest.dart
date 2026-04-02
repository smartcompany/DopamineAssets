import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../data/models/asset_news.dart';

const _trackingParams = {
  'utm_source',
  'utm_medium',
  'utm_campaign',
  'utm_content',
  'utm_term',
  'utm_id',
  'fbclid',
  'gclid',
  'mc_cid',
  'mc_eid',
  'ref',
  'ref_src',
};

/// 서버 `news-ai-summary-cache.ts` 의 [normalizeNewsUrl] 과 동일 규칙.
String normalizeNewsUrlForAi(String urlStr) {
  try {
    final u = Uri.parse(urlStr.trim());
    if (u.scheme != 'http' && u.scheme != 'https') return urlStr.trim();
    final q = Map<String, String>.from(u.queryParameters);
    q.removeWhere((k, _) {
      final kl = k.toLowerCase();
      return _trackingParams.contains(kl) || kl.startsWith('utm_');
    });
    final rebuilt = Uri(
      scheme: u.scheme,
      host: u.host,
      port: u.hasPort ? u.port : null,
      path: u.path,
      queryParameters: q.isEmpty ? null : q,
    );
    return rebuilt.toString();
  } catch (_) {
    return urlStr.trim();
  }
}

/// AI 뉴스 요약 캐시 키용: URL 정규화 → 중복 제거 → 정렬 → 최대 5개.
List<String> canonicalNewsUrlsForAi(Iterable<AssetNewsItem> items) {
  final seen = <String>{};
  final out = <String>[];
  for (final e in items) {
    final u = normalizeNewsUrlForAi(e.url);
    if (u.isEmpty || seen.contains(u)) continue;
    seen.add(u);
    out.add(u);
  }
  out.sort();
  return out.length > 5 ? out.sublist(0, 5) : out;
}

/// 정렬된 URL 목록에 대응하는 제목들을 알파벳 순으로 모아 해시.
String buildNewsTitleDigestForCanonicalUrls(
  List<AssetNewsItem> items,
  List<String> canonicalUrls,
) {
  final byUrl = <String, String>{};
  for (final i in items) {
    final nu = normalizeNewsUrlForAi(i.url);
    byUrl[nu] = i.title.trim();
  }
  final titles = canonicalUrls.map((u) => byUrl[u] ?? '').toList()
    ..sort();
  final bytes = utf8.encode(titles.join('\n'));
  return sha256.convert(bytes).toString();
}

/// [canonicalUrls] 순서와 1:1로 대응하는 기사 제목 (서버 AI 프롬프트용).
List<String> articleTitlesForCanonicalUrls(
  List<AssetNewsItem> items,
  List<String> canonicalUrls,
) {
  final byUrl = <String, String>{};
  for (final i in items) {
    byUrl[normalizeNewsUrlForAi(i.url)] = i.title.trim();
  }
  return canonicalUrls.map((u) => byUrl[u] ?? '').toList();
}
