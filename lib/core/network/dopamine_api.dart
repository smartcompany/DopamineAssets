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
import '../../data/models/profile_activity_item.dart';
import '../push/push_prefs_keys.dart';

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

  /// [locale]: `ko` | `en` 등 — 서버가 테마 표시 이름을 맞춤. 비우면 Accept-Language / en.
  static Future<List<ThemeItem>> fetchThemes(
    String kind, {
    String? locale,
  }) async {
    final q = <String, String>{'kind': kind};
    if (locale != null && locale.isNotEmpty) {
      q['locale'] = locale;
    }
    final response = await _client.get(
      _uri('/api/themes').replace(queryParameters: q),
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
    final tid = asset.themeId?.trim();
    if (tid != null && tid.isNotEmpty) {
      q['themeId'] = tid;
    }
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

  /// 테마 구성 종목 일봉을 정규화·평균한 합성 시리즈. [range]: `1mo` | `3mo` | `1y`.
  static Future<List<AssetChartBar>> fetchThemeChartBars({
    required String themeId,
    String range = '3mo',
  }) async {
    final uri = _uri('/api/feed/theme-chart').replace(
      queryParameters: <String, String>{
        'themeId': themeId,
        'range': range,
      },
    );
    final response = await _client.get(uri, headers: _jsonHeaders);
    if (kDebugMode) {
      debugPrint('[DopamineApi][theme-chart] GET $uri');
      debugPrint(
        '[DopamineApi][theme-chart] status=${response.statusCode}',
      );
    }
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid theme chart payload');
    }
    final raw = decoded['bars'];
    if (raw is! List<dynamic>) {
      throw ApiException('Invalid theme chart bars');
    }
    return raw
        .map((e) => AssetChartBar.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 뉴스 검색어를 직접 지정 (테마명 등).
  static Future<AssetNewsFeed> fetchNewsBySearchQuery({
    required String q,
    String assetClass = 'us_stock',
    int limit = 8,
  }) async {
    final uri = _uri('/api/feed/asset-news').replace(
      queryParameters: {
        'q': q,
        'limit': limit.clamp(1, 30).toString(),
        'assetClass': assetClass,
      },
    );
    final response = await _client.get(uri, headers: _jsonHeaders);
    if (kDebugMode) {
      debugPrint('[DopamineApi][asset-news-query] GET $uri');
      debugPrint(
        '[DopamineApi][asset-news-query] status=${response.statusCode}',
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

  static Future<NewsAiSummary> fetchNewsAiSummary({
    required List<String> urls,
    required String symbol,
    required String assetClass,
    required String assetName,
    required String locale,
    required String titleDigest,
  }) async {
    final cleanUrls = urls
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cleanUrls.isEmpty) {
      throw ApiException('Missing news urls');
    }
    final response = await _client.post(
      _uri('/api/feed/news-ai-summary'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'urls': cleanUrls,
        'symbol': symbol,
        'assetClass': assetClass,
        'assetName': assetName,
        'locale': locale,
        'titleDigest': titleDigest,
      }),
    );
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid news ai summary payload');
    }
    if (kDebugMode) {
      final hit = decoded['cached'] == true;
      debugPrint(
        '[DopamineApi][news-ai-summary] cached=$hit symbol=$symbol',
      );
    }
    return NewsAiSummary.fromJson(decoded);
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
    String? symbol,
    String? assetClass,
    String? authorUid,
    List<String>? bodyTerms,
    String? idToken,
  }) async {
    final q = <String, String>{
      'sort': sort,
      if (symbol != null &&
          symbol.isNotEmpty &&
          assetClass != null &&
          assetClass.isNotEmpty) ...{
        'symbol': symbol,
        'assetClass': assetClass,
      },
      if (bodyTerms != null && bodyTerms.isNotEmpty)
        'q': bodyTerms.join(','),
      if (authorUid != null && authorUid.isNotEmpty) 'authorUid': authorUid,
    };
    final uri = _uri('/api/feed/community-posts').replace(
      queryParameters: q,
    );
    final headers =
        idToken != null && idToken.isNotEmpty ? _bearerHeaders(idToken) : _jsonHeaders;
    final response = await _client.get(uri, headers: headers);
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

  static Future<Map<String, dynamic>> fetchPublicProfile({
    required String uid,
    String? idToken,
  }) async {
    final uri = _uri('/api/profile/public').replace(
      queryParameters: {'uid': uid},
    );
    final headers =
        idToken != null && idToken.isNotEmpty ? _bearerHeaders(idToken) : _jsonHeaders;
    final response = await _client.get(uri, headers: headers);
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid public profile payload');
    }
    return decoded;
  }

  static Future<void> blockUser({
    required String idToken,
    required String targetUid,
  }) async {
    final response = await _client.post(
      _uri('/api/profile/block'),
      headers: _bearerHeaders(idToken),
      body: jsonEncode({'targetUid': targetUid}),
    );
    _ensureOk(response);
  }

  static Future<void> unblockUser({
    required String idToken,
    required String targetUid,
  }) async {
    final uri = _uri('/api/profile/block').replace(
      queryParameters: {'targetUid': targetUid},
    );
    final response = await _client.delete(
      uri,
      headers: _bearerHeaders(idToken),
    );
    _ensureOk(response);
  }

  static Future<List<AssetComment>> fetchAssetComments({
    required String symbol,
    required String assetClass,
    String? idToken,
  }) async {
    final uri = _uri('/api/feed/asset-comments').replace(
      queryParameters: {
        'symbol': symbol,
        'assetClass': assetClass,
      },
    );
    final headers =
        idToken != null && idToken.isNotEmpty ? _bearerHeaders(idToken) : _jsonHeaders;
    final response = await _client.get(uri, headers: headers);
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
    String? title,
    List<String>? imageUrls,
    String? assetDisplayName,
    required String idToken,
  }) async {
    final uri = _uri('/api/feed/asset-comments');
    final payload = <String, dynamic>{
      'symbol': symbol,
      'assetClass': assetClass,
      'body': body,
      'parentId': parentId,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (imageUrls != null && imageUrls.isNotEmpty) 'imageUrls': imageUrls,
      if (assetDisplayName != null && assetDisplayName.trim().isNotEmpty)
        'assetDisplayName': assetDisplayName.trim(),
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

  static Future<List<AssetComment>> fetchAssetCommentThread({
    required String rootCommentId,
    String? idToken,
  }) async {
    final path =
        '/api/feed/asset-comments/${Uri.encodeComponent(rootCommentId)}/thread';
    final uri = _uri(path);
    final headers =
        idToken != null && idToken.isNotEmpty ? _bearerHeaders(idToken) : _jsonHeaders;
    final response = await _client.get(uri, headers: headers);
    if (kDebugMode) {
      debugPrint('[DopamineApi][asset-comments] GET thread $uri');
    }
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid comment thread payload');
    }
    final items = decoded['items'];
    if (items is! List<dynamic>) {
      throw ApiException('Invalid comment thread items');
    }
    return items
        .map((e) => AssetComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<AssetComment> fetchAssetCommentById({
    required String id,
    String? idToken,
  }) async {
    final path =
        '/api/feed/asset-comments/${Uri.encodeComponent(id)}';
    final uri = _uri(path);
    final headers =
        idToken != null && idToken.isNotEmpty ? _bearerHeaders(idToken) : _jsonHeaders;
    final response = await _client.get(uri, headers: headers);
    if (kDebugMode) {
      debugPrint('[DopamineApi][asset-comments] GET $uri');
    }
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid asset comment payload');
    }
    final item = decoded['item'];
    if (item is! Map<String, dynamic>) {
      throw ApiException('Invalid asset comment item');
    }
    return AssetComment.fromJson(item);
  }

  static Future<AssetComment> patchAssetComment({
    required String id,
    required String body,
    String? title,
    required List<String> imageUrls,
    required String idToken,
  }) async {
    final path =
        '/api/feed/asset-comments/${Uri.encodeComponent(id)}';
    final uri = _uri(path);
    final payload = <String, dynamic>{
      'body': body,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      'imageUrls': imageUrls,
    };
    final response = await _client.patch(
      uri,
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(payload),
    );
    if (kDebugMode) {
      debugPrint('[DopamineApi][asset-comments] PATCH $uri');
    }
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid patch comment response');
    }
    final item = decoded['item'];
    if (item is! Map<String, dynamic>) {
      throw ApiException('Invalid patch comment item');
    }
    return AssetComment.fromJson(item);
  }

  static Future<void> deleteAssetComment({
    required String id,
    required String idToken,
  }) async {
    final path =
        '/api/feed/asset-comments/${Uri.encodeComponent(id)}';
    final uri = _uri(path);
    final response = await _client.delete(
      uri,
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );
    if (kDebugMode) {
      debugPrint('[DopamineApi][asset-comments] DELETE $uri');
    }
    _ensureOk(response);
  }

  static Future<void> reportAssetComment({
    required String commentId,
    required String idToken,
    String? reason,
  }) async {
    final path =
        '/api/feed/asset-comments/${Uri.encodeComponent(commentId)}/report';
    final uri = _uri(path);
    final payload = <String, dynamic>{
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
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
      debugPrint('[DopamineApi][asset-comments] POST report $uri');
    }
    _ensureOk(response);
  }

  static Future<ProfileStats> fetchProfileStats({
    required String idToken,
  }) async {
    final response = await _client.get(
      _uri('/api/profile/stats'),
      headers: _bearerHeaders(idToken),
    );
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid profile stats');
    }
    return ProfileStats.fromJson(decoded);
  }

  static Future<List<ProfileActivityItem>> fetchProfileActivity({
    required String idToken,
  }) async {
    final response = await _client.get(
      _uri('/api/profile/activity'),
      headers: _bearerHeaders(idToken),
    );
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid profile activity');
    }
    final items = decoded['items'];
    if (items is! List<dynamic>) {
      throw ApiException('Invalid profile activity items');
    }
    return items
        .map((e) => ProfileActivityItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ProfileUserRow>> fetchProfileFollowing({
    required String idToken,
  }) async {
    final response = await _client.get(
      _uri('/api/profile/following'),
      headers: _bearerHeaders(idToken),
    );
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid following list');
    }
    final items = decoded['items'];
    if (items is! List<dynamic>) {
      throw ApiException('Invalid following items');
    }
    return items
        .map((e) => ProfileUserRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ProfileUserRow>> fetchProfileFollowers({
    required String idToken,
  }) async {
    final response = await _client.get(
      _uri('/api/profile/followers'),
      headers: _bearerHeaders(idToken),
    );
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid followers list');
    }
    final items = decoded['items'];
    if (items is! List<dynamic>) {
      throw ApiException('Invalid followers items');
    }
    return items
        .map((e) => ProfileUserRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ProfileUserRow>> fetchProfileBlockedUsers({
    required String idToken,
  }) async {
    final response = await _client.get(
      _uri('/api/profile/blocked'),
      headers: _bearerHeaders(idToken),
    );
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid blocked users list');
    }
    final items = decoded['items'];
    if (items is! List<dynamic>) {
      throw ApiException('Invalid blocked users items');
    }
    return items
        .map((e) => ProfileUserRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> patchProfileDisplayName({
    required String idToken,
    required String displayName,
  }) async {
    final response = await _client.patch(
      _uri('/api/profile/me'),
      headers: _jsonBearerHeaders(idToken),
      body: jsonEncode({'displayName': displayName}),
    );
    _ensureOk(response);
  }

  static Future<void> patchProfilePhotoUrl({
    required String idToken,
    String? photoUrl,
  }) async {
    final response = await _client.patch(
      _uri('/api/profile/me'),
      headers: _jsonBearerHeaders(idToken),
      body: jsonEncode({'photoUrl': photoUrl}),
    );
    _ensureOk(response);
  }

  static Future<void> deleteProfileData({
    required String idToken,
  }) async {
    final response = await _client.delete(
      _uri('/api/profile/me'),
      headers: _bearerHeaders(idToken),
    );
    _ensureOk(response);
  }

  static Future<void> registerPushToken({
    required String idToken,
    required String fcmToken,
    String? platform,
  }) async {
    final body = <String, dynamic>{
      'fcmToken': fcmToken,
      if (platform != null && platform.isNotEmpty) 'platform': platform,
    };
    final response = await _client.post(
      _uri('/api/profile/push-token'),
      headers: _jsonBearerHeaders(idToken),
      body: jsonEncode(body),
    );
    _ensureOk(response);
  }

  static Future<void> deletePushToken({
    required String idToken,
    required String fcmToken,
  }) async {
    final response = await _client.delete(
      _uri('/api/profile/push-token'),
      headers: _jsonBearerHeaders(idToken),
      body: jsonEncode({'fcmToken': fcmToken}),
    );
    _ensureOk(response);
  }

  static Future<Map<String, dynamic>> fetchPushPrefs({
    required String idToken,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[DopamineApi][push-prefs] GET ${_uri('/api/profile/push-prefs')}',
      );
    }
    final response = await _client.get(
      _uri('/api/profile/push-prefs'),
      headers: _bearerHeaders(idToken),
    );
    if (kDebugMode) {
      debugPrint(
        '[DopamineApi][push-prefs] status=${response.statusCode} body=${response.body}',
      );
    }
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['prefs'] is! Map) {
      throw ApiException('Invalid push prefs payload');
    }
    final prefs = decoded['prefs'] as Map<String, dynamic>;
    return <String, dynamic>{
      PushPrefsKeys.masterEnabled: prefs['masterEnabled'],
      PushPrefsKeys.socialReply: prefs['socialReply'],
      PushPrefsKeys.socialLike: prefs['socialLike'],
      PushPrefsKeys.followedNewPost: prefs['followedNewPost'],
      PushPrefsKeys.moderationNotice: prefs['moderationNotice'],
      PushPrefsKeys.marketDailyBrief: prefs['marketDailyBrief'],
      PushPrefsKeys.marketWatchlist: prefs['marketWatchlist'],
      PushPrefsKeys.marketTheme: prefs['marketTheme'],
    };
  }

  static Future<Map<String, dynamic>> patchPushPrefs({
    required String idToken,
    required Map<String, dynamic> patch,
  }) async {
    // snake_case → camelCase 변환
    final body = <String, dynamic>{};
    void mapKey(String snake, String camel) {
      if (patch.containsKey(snake)) {
        body[camel] = patch[snake];
      }
    }
    mapKey(PushPrefsKeys.masterEnabled, 'masterEnabled');
    mapKey(PushPrefsKeys.socialReply, 'socialReply');
    mapKey(PushPrefsKeys.socialLike, 'socialLike');
    mapKey(PushPrefsKeys.followedNewPost, 'followedNewPost');
    mapKey(PushPrefsKeys.moderationNotice, 'moderationNotice');
    mapKey(PushPrefsKeys.marketDailyBrief, 'marketDailyBrief');
    mapKey(PushPrefsKeys.marketWatchlist, 'marketWatchlist');
    mapKey(PushPrefsKeys.marketTheme, 'marketTheme');

    if (kDebugMode) {
      debugPrint(
        '[DopamineApi][push-prefs] PATCH ${_uri('/api/profile/push-prefs')}',
      );
      debugPrint('[DopamineApi][push-prefs] payload=$body');
    }
    final response = await _client.patch(
      _uri('/api/profile/push-prefs'),
      headers: _jsonBearerHeaders(idToken),
      body: jsonEncode(body),
    );
    if (kDebugMode) {
      debugPrint(
        '[DopamineApi][push-prefs] status=${response.statusCode} body=${response.body}',
      );
    }
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['prefs'] is! Map) {
      throw ApiException('Invalid patch push prefs payload');
    }
    final prefs = decoded['prefs'] as Map<String, dynamic>;
    return <String, dynamic>{
      PushPrefsKeys.masterEnabled: prefs['masterEnabled'],
      PushPrefsKeys.socialReply: prefs['socialReply'],
      PushPrefsKeys.socialLike: prefs['socialLike'],
      PushPrefsKeys.followedNewPost: prefs['followedNewPost'],
      PushPrefsKeys.moderationNotice: prefs['moderationNotice'],
      PushPrefsKeys.marketDailyBrief: prefs['marketDailyBrief'],
      PushPrefsKeys.marketWatchlist: prefs['marketWatchlist'],
      PushPrefsKeys.marketTheme: prefs['marketTheme'],
    };
  }

  static Future<void> followUser({
    required String idToken,
    required String targetUid,
  }) async {
    final response = await _client.post(
      _uri('/api/profile/follow'),
      headers: _jsonBearerHeaders(idToken),
      body: jsonEncode({'targetUid': targetUid}),
    );
    _ensureOk(response);
  }

  static Future<void> unfollowUser({
    required String idToken,
    required String targetUid,
  }) async {
    final uri = _uri('/api/profile/follow').replace(
      queryParameters: {'targetUid': targetUid},
    );
    final response = await _client.delete(uri, headers: _bearerHeaders(idToken));
    _ensureOk(response);
  }

  static Future<Map<String, bool>> fetchFollowStatus({
    required String idToken,
    required List<String> targetUids,
  }) async {
    if (targetUids.isEmpty) return {};
    final response = await _client.post(
      _uri('/api/profile/follow-status'),
      headers: _jsonBearerHeaders(idToken),
      body: jsonEncode({'targetUids': targetUids}),
    );
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid follow status');
    }
    final raw = decoded['following'];
    if (raw is! Map<String, dynamic>) {
      throw ApiException('Invalid follow status map');
    }
    return raw.map((k, v) => MapEntry(k, v == true));
  }

  /// 서버 토글 후 현재 좋아요 여부와 개수.
  static Future<({bool liked, int likeCount})> toggleCommentLike({
    required String idToken,
    required String commentId,
  }) async {
    final response = await _client.post(
      _uri('/api/feed/comment-like'),
      headers: _jsonBearerHeaders(idToken),
      body: jsonEncode({'commentId': commentId}),
    );
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid comment like response');
    }
    return (
      liked: decoded['liked'] as bool? ?? false,
      likeCount: (decoded['likeCount'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, String> _bearerHeaders(String idToken) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

  static Map<String, String> _jsonBearerHeaders(String idToken) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

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
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message'];
        if (msg is String && msg.isNotEmpty) {
          throw ApiException(msg);
        }
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          throw ApiException(detail);
        }
        final err = decoded['error'];
        if (err is String && err.isNotEmpty) {
          throw ApiException(err);
        }
      }
    } catch (e) {
      if (e is ApiException) rethrow;
    }
    throw ApiException('HTTP ${response.statusCode}');
  }
}
