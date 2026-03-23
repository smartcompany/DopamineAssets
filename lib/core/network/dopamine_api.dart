import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart' show ApiConfig;
import 'api_exception.dart';
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
