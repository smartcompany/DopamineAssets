import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/upload_limits.dart';
import 'giphy_config.dart';

/// 서버·프록시 업로드 한도와 동일 ([kCommunityImageUploadMaxBytes]).
const int kGiphyMaxDownloadBytes = kCommunityImageUploadMaxBytes;

final class GiphyApiException implements Exception {
  GiphyApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

/// 그리드·다운로드에 쓸 GIPHY 항목 요약.
final class GiphyGifSummary {
  const GiphyGifSummary({
    required this.id,
    required this.previewUrl,
    required this.downloadUrl,
    this.downloadSizeBytes,
  });

  final String id;
  final String previewUrl;
  final String downloadUrl;
  final int? downloadSizeBytes;

  static GiphyGifSummary? parse(Map<String, dynamic> m) {
    final id = m['id'] as String?;
    if (id == null || id.isEmpty) return null;
    final images = m['images'];
    if (images is! Map<String, dynamic>) return null;

    String? urlOf(String rendition, String field) {
      final o = images[rendition];
      if (o is Map<String, dynamic>) {
        final u = o[field];
        if (u is String && u.isNotEmpty) return u;
      }
      return null;
    }

    int? sizeOf(String rendition) {
      final o = images[rendition];
      if (o is Map<String, dynamic>) {
        final s = o['size'];
        if (s is String) return int.tryParse(s);
        if (s is int) return s;
      }
      return null;
    }

    final preview =
        urlOf('fixed_width_small', 'url') ??
        urlOf('fixed_height_small', 'url') ??
        urlOf('preview_gif', 'url') ??
        urlOf('downsized_still', 'url');
    if (preview == null) return null;

    // 표시·저장은 GIPHY CDN URL(hotlink). 메타 size는 참고용(너무 큰 항목 경고).
    String download = urlOf('downsized_medium', 'url') ?? '';
    var dlSize = sizeOf('downsized_medium');
    if (download.isEmpty) {
      download = urlOf('downsized', 'url') ?? '';
      dlSize = sizeOf('downsized');
    }
    if (download.isEmpty) {
      download = urlOf('fixed_width', 'url') ?? '';
      dlSize = sizeOf('fixed_width');
    }
    if (download.isEmpty) {
      download = urlOf('fixed_height', 'url') ?? '';
      dlSize = sizeOf('fixed_height');
    }
    if (download.isEmpty) return null;

    return GiphyGifSummary(
      id: id,
      previewUrl: preview,
      downloadUrl: download,
      downloadSizeBytes: dlSize,
    );
  }
}

Uri _trendingUri({required String apiKey, int limit = 24, int offset = 0}) {
  return Uri.https('api.giphy.com', '/v1/gifs/trending', {
    'api_key': apiKey,
    'limit': '$limit',
    'offset': '$offset',
    'rating': 'pg-13',
  });
}

Uri _searchUri({
  required String apiKey,
  required String query,
  int limit = 24,
  int offset = 0,
}) {
  return Uri.https('api.giphy.com', '/v1/gifs/search', {
    'api_key': apiKey,
    'q': query,
    'limit': '$limit',
    'offset': '$offset',
    'rating': 'pg-13',
    'lang': 'ko',
  });
}

Future<List<GiphyGifSummary>> giphyFetchTrending({
  int limit = 24,
  int offset = 0,
}) async {
  final key = giphyApiKeyForPlatform();
  if (key == null) {
    throw GiphyApiException('missing_api_key');
  }
  final uri = _trendingUri(apiKey: key, limit: limit, offset: offset);
  final res = await http.get(uri);
  if (res.statusCode == 429) {
    throw GiphyApiException('rate_limited', statusCode: 429);
  }
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw GiphyApiException('http_${res.statusCode}', statusCode: res.statusCode);
  }
  final decoded = jsonDecode(res.body);
  if (decoded is! Map<String, dynamic>) return [];
  final data = decoded['data'];
  if (data is! List) return [];
  final out = <GiphyGifSummary>[];
  for (final item in data) {
    if (item is Map<String, dynamic>) {
      final g = GiphyGifSummary.parse(item);
      if (g != null) out.add(g);
    }
  }
  return out;
}

Future<List<GiphyGifSummary>> giphyFetchSearch({
  required String query,
  int limit = 24,
  int offset = 0,
}) async {
  final q = query.trim();
  if (q.isEmpty) {
    return giphyFetchTrending(limit: limit, offset: offset);
  }
  final key = giphyApiKeyForPlatform();
  if (key == null) {
    throw GiphyApiException('missing_api_key');
  }
  final uri = _searchUri(
    apiKey: key,
    query: q,
    limit: limit,
    offset: offset,
  );
  final res = await http.get(uri);
  if (res.statusCode == 429) {
    throw GiphyApiException('rate_limited', statusCode: 429);
  }
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw GiphyApiException('http_${res.statusCode}', statusCode: res.statusCode);
  }
  final decoded = jsonDecode(res.body);
  if (decoded is! Map<String, dynamic>) return [];
  final data = decoded['data'];
  if (data is! List) return [];
  final out = <GiphyGifSummary>[];
  for (final item in data) {
    if (item is Map<String, dynamic>) {
      final g = GiphyGifSummary.parse(item);
      if (g != null) out.add(g);
    }
  }
  return out;
}
