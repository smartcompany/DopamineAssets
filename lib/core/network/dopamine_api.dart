import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart' show ApiConfig;
import 'api_exception.dart';
import '../../data/models/asset_chart_bar.dart';
import '../../data/models/asset_comment.dart';
import '../../data/models/community_post.dart';
import '../../data/models/asset_detail.dart';
import '../../data/models/asset_news.dart';
import '../../data/models/market_summary.dart';
import '../../data/models/ranked_asset.dart';
import '../../data/models/theme_item.dart';

abstract final class DopamineApi {
  DopamineApi._();

  static final _client = http.Client();

  static Uri _uri(String path) {
    return Uri.parse('${ApiConfig.baseUrl}$path');
  }

  static Future<List<RankedAsset>> fetchRankingsUp({
    Set<String>? includeAssetClasses,
  }) async {
    final response = await _client.get(
      _uri('/api/feed/rankings/up').replace(
        queryParameters: _rankingsQuery(includeAssetClasses),
      ),
      headers: _jsonHeaders,
    );
    return _decodeRankings(response);
  }

  static Future<List<RankedAsset>> fetchRankingsDown({
    Set<String>? includeAssetClasses,
  }) async {
    final response = await _client.get(
      _uri('/api/feed/rankings/down').replace(
        queryParameters: _rankingsQuery(includeAssetClasses),
      ),
      headers: _jsonHeaders,
    );
    return _decodeRankings(response);
  }

  static Map<String, String> _rankingsQuery(Set<String>? includeAssetClasses) {
    final q = <String, String>{
      'limit': '10',
      'source': ApiConfig.rankingSource,
    };
    if (includeAssetClasses != null && includeAssetClasses.isNotEmpty) {
      q['include'] = includeAssetClasses.join(',');
    }
    return q;
  }

  static Future<List<ThemeItem>> fetchThemes(String kind) async {
    final response = await _client.get(
      _uri('/api/themes').replace(queryParameters: {'kind': kind}),
      headers: _jsonHeaders,
    );
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid themes payload');
    }
    final items = decoded['items'];
    if (items is! List<dynamic>) {
      throw ApiException('Invalid themes items');
    }
    return items
        .map((e) => ThemeItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<AssetDetail> fetchAssetDetail({
    required RankedAsset asset,
  }) async {
    final ac = asset.assetClass;
    if (ac == null || ac.isEmpty) {
      throw ApiException('Missing asset class');
    }
    final q = <String, String>{
      'symbol': asset.symbol,
      'assetClass': ac,
      'name': asset.name,
    };
    if (asset.commodityKind != null && asset.commodityKind!.isNotEmpty) {
      q['commodityKind'] = asset.commodityKind!;
    }
    final uri = _uri('/api/feed/asset-detail').replace(queryParameters: q);
    final response = await _client.get(uri, headers: _jsonHeaders);
    if (kDebugMode) {
      debugPrint('[DopamineApi][asset-detail] GET $uri');
      debugPrint(
        '[DopamineApi][asset-detail] status=${response.statusCode} body=${response.body}',
      );
    }
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid asset detail payload');
    }
    return AssetDetail.fromJson(decoded);
  }

  /// 일봉 OHLC (서버 → Yahoo). [range]: `1mo` | `3mo` | `1y`.
  static Future<List<AssetChartBar>> fetchAssetChartBars({
    required String symbol,
    required String assetClass,
    String range = '3mo',
  }) async {
    final uri = _uri('/api/feed/asset-chart').replace(
      queryParameters: <String, String>{
        'symbol': symbol,
        'assetClass': assetClass,
        'range': range,
      },
    );
    final response = await _client.get(uri, headers: _jsonHeaders);
    if (kDebugMode) {
      debugPrint('[DopamineApi][asset-chart] GET $uri');
      debugPrint(
        '[DopamineApi][asset-chart] status=${response.statusCode}',
      );
    }
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid asset chart payload');
    }
    final raw = decoded['bars'];
    if (raw is! List<dynamic>) {
      throw ApiException('Invalid asset chart bars');
    }
    return raw
        .map((e) => AssetChartBar.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 외부 뉴스 소스. 실패해도 예외 대신 [AssetNewsFeed.loadFailed] 로 표시.
  static Future<AssetNewsFeed> fetchAssetNews({
    required String assetClass,
    required String symbol,
    required String name,
    int limit = 8,
  }) async {
    final q = assetNewsSearchQuery(
      assetClass: assetClass,
      symbol: symbol,
      name: name,
    );
    final uri = _uri('/api/feed/asset-news').replace(
      queryParameters: {
        'q': q,
        'limit': limit.clamp(1, 30).toString(),
        'assetClass': assetClass,
      },
    );
    final response = await _client.get(uri, headers: _jsonHeaders);
    if (kDebugMode) {
      debugPrint('[DopamineApi][asset-news] GET $uri');
      debugPrint(
        '[DopamineApi][asset-news] status=${response.statusCode}',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const AssetNewsFeed(items: [], loadFailed: true);
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const AssetNewsFeed(items: [], loadFailed: true);
      }
      final raw = decoded['items'];
      if (raw is! List<dynamic>) {
        return const AssetNewsFeed(items: [], loadFailed: true);
      }
      final items = <AssetNewsItem>[];
      for (final e in raw) {
        if (e is! Map<String, dynamic>) continue;
        final title = e['title'] as String? ?? '';
        final url = e['url'] as String? ?? '';
        if (title.isEmpty || url.isEmpty) continue;
        items.add(AssetNewsItem.fromJson(e));
      }
      return AssetNewsFeed(items: items);
    } catch (_) {
      return const AssetNewsFeed(items: [], loadFailed: true);
    }
  }

  static Future<MarketSummary> fetchMarketSummary() async {
    final response = await _client.get(
      _uri('/api/market-summary'),
      headers: _jsonHeaders,
    );
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid market summary payload');
    }
    return MarketSummary.fromJson(decoded);
  }

  /// [sort]: `latest` | `popular` — 루트 게시글만(답글 제외).
  static Future<List<CommunityPost>> fetchCommunityPosts({
    required String sort,
  }) async {
    final uri = _uri('/api/feed/community-posts').replace(
      queryParameters: {'sort': sort},
    );
    final response = await _client.get(uri, headers: _jsonHeaders);
    if (kDebugMode) {
      debugPrint('[DopamineApi][community-posts] GET $uri');
    }
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid community posts payload');
    }
    final items = decoded['items'];
    if (items is! List<dynamic>) {
      throw ApiException('Invalid community posts items');
    }
    return items
        .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<AssetComment>> fetchAssetComments({
    required String symbol,
    required String assetClass,
  }) async {
    final uri = _uri('/api/feed/asset-comments').replace(
      queryParameters: {
        'symbol': symbol,
        'assetClass': assetClass,
      },
    );
    final response = await _client.get(uri, headers: _jsonHeaders);
    if (kDebugMode) {
      debugPrint('[DopamineApi][asset-comments] GET $uri');
    }
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid asset comments payload');
    }
    final items = decoded['items'];
    if (items is! List<dynamic>) {
      throw ApiException('Invalid asset comments items');
    }
    return items
        .map((e) => AssetComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<AssetComment> postAssetComment({
    required String symbol,
    required String assetClass,
    required String body,
    String? parentId,
    required String idToken,
  }) async {
    final uri = _uri('/api/feed/asset-comments');
    final payload = <String, dynamic>{
      'symbol': symbol,
      'assetClass': assetClass,
      'body': body,
      'parentId': parentId,
    };
    final response = await _client.post(
      uri,
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(payload),
    );
    if (kDebugMode) {
      debugPrint('[DopamineApi][asset-comments] POST $uri');
    }
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid post comment response');
    }
    final item = decoded['item'];
    if (item is! Map<String, dynamic>) {
      throw ApiException('Invalid post comment item');
    }
    return AssetComment.fromJson(item);
  }

  static Map<String, String> get _jsonHeaders => const {
        'Accept': 'application/json',
      };

  static List<RankedAsset> _decodeRankings(http.Response response) {
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid rankings payload');
    }
    final items = decoded['items'];
    if (items is! List<dynamic>) {
      throw ApiException('Invalid rankings items');
    }
    return items
        .map((e) => RankedAsset.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static void _ensureOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('HTTP ${response.statusCode}');
    }
  }
}
