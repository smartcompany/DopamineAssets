/// `/api/feed/asset-news` 응답의 단일 기사.
final class AssetNewsItem {
  const AssetNewsItem({
    required this.title,
    required this.url,
    this.publishedAt,
    this.source,
  });

  final String title;
  final String url;
  final String? publishedAt;
  final String? source;

  factory AssetNewsItem.fromJson(Map<String, dynamic> json) {
    return AssetNewsItem(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      publishedAt: json['publishedAt'] as String?,
      source: json['source'] as String?,
    );
  }
}

/// 뉴스 피드 로드 결과 (API 오류 시에도 상세 화면 전체는 유지).
final class AssetNewsFeed {
  const AssetNewsFeed({
    required this.items,
    this.loadFailed = false,
  });

  final List<AssetNewsItem> items;
  final bool loadFailed;
}

final class NewsAiSummary {
  const NewsAiSummary({
    required this.summary,
    required this.impact,
    required this.risk,
    required this.sourceUrl,
  });

  final String summary;
  final List<String> impact;
  final List<String> risk;
  final String sourceUrl;

  factory NewsAiSummary.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic raw, int maxLen) {
      if (raw is! List<dynamic>) return const [];
      return raw
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .take(maxLen)
          .toList();
    }

    return NewsAiSummary(
      summary: (json['summary'] as String? ?? '').trim(),
      impact: parseList(json['impact'], 3),
      risk: parseList(json['risk'], 2),
      sourceUrl: (json['sourceUrl'] as String? ?? '').trim(),
    );
  }
}

String _stripCompanyLegalSuffix(String name) {
  return name
      .trim()
      .replaceAll(
        RegExp(
          r',?\s*(Inc\.?|Incorporated|Corp\.?|Corporation|LLC|L\.L\.C\.|Ltd\.?|Limited|PLC|S\.A\.|N\.V\.)\s*$',
          caseSensitive: false,
        ),
        '',
      )
      .trim();
}

/// 자산 종류·심볼·이름으로 뉴스 검색어 구성 (영문 쿼리 위주).
String assetNewsSearchQuery({
  required String assetClass,
  required String symbol,
  required String name,
}) {
  final sym = symbol.trim();
  final nm = name.trim();
  switch (assetClass) {
    case 'crypto':
      if (sym.isNotEmpty) {
        return '$sym cryptocurrency';
      }
      return '${nm.isNotEmpty ? nm : 'crypto'} cryptocurrency';
    case 'us_stock':
      // 티커만 쓰면(예: APGE stock) 광범위한 시장 뉴스가 섞이므로 회사명+티커를 함께 넣는다.
      final clean = _stripCompanyLegalSuffix(nm);
      final parts = <String>[];
      if (clean.isNotEmpty) {
        parts.add(clean);
      }
      if (sym.isNotEmpty) {
        parts.add(sym);
      }
      if (parts.isEmpty) {
        return 'US stock';
      }
      parts.add('stock');
      var q = parts.join(' ');
      if (q.length > 200) {
        q = q.substring(0, 200).trim();
      }
      return q;
    case 'kr_stock':
      // Google News RSS 한국(hl=ko) 검색에 맞춘 한국어 쿼리
      if (nm.isNotEmpty) {
        return '$nm 주식';
      }
      if (sym.isNotEmpty) {
        return '$sym 주식';
      }
      return '코스피';
    case 'commodity':
      if (nm.isNotEmpty) {
        return '$nm commodity';
      }
      return '${sym.isNotEmpty ? sym : 'commodity'} commodity';
    default:
      if (nm.isNotEmpty) {
        return nm;
      }
      return sym.isNotEmpty ? sym : 'market';
  }
}
