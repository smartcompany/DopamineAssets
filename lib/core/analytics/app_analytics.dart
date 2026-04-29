import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../badges/badge_unlock_center.dart';

/// Firebase Analytics 공통 래퍼.
/// 이벤트명/파라미터를 한 곳에서 관리해 화면별 코드 침습을 줄입니다.
final class AppAnalytics {
  static FirebaseAnalytics get _fa => FirebaseAnalytics.instance;

  static Future<void> logHomeSectionTap({
    required String sectionId,
    required String locale,
  }) => _log(
    'home_section_tap',
    <String, Object>{
      'section_id': _normalize(sectionId),
      'locale': _normalize(locale),
    },
  );

  static Future<void> logRankingFilterApplied({
    required int selectedCount,
    required String locale,
  }) => _log(
    'home_ranking_filter_applied',
    <String, Object>{
      'selected_count': _clampCount(selectedCount),
      'locale': _normalize(locale),
    },
  );

  static Future<void> logView50Opened({
    required String section,
    required int itemCount,
    required String locale,
  }) => _log(
    'home_view50_opened',
    <String, Object>{
      'section': _normalize(section),
      'item_count': _clampCount(itemCount),
      'locale': _normalize(locale),
    },
  );

  static Future<void> logAssetDetailOpen({
    required String source,
    required String symbol,
    required String assetClass,
    required String locale,
  }) => _log(
    'asset_detail_open',
    <String, Object>{
      'source': _normalize(source),
      'symbol': _normalize(symbol),
      'asset_class': _normalize(assetClass),
      'locale': _normalize(locale),
    },
  );

  static Future<void> logFavoriteToggled({
    required String symbol,
    required String assetClass,
    required bool favored,
    required String source,
  }) => _log(
    'favorite_toggled',
    <String, Object>{
      'symbol': _normalize(symbol),
      'asset_class': _normalize(assetClass),
      'favored': favored,
      'source': _normalize(source),
    },
  );

  static Future<void> logCommunityPostOpen({
    required String source,
    required String postId,
    required String assetClass,
  }) => _log(
    'community_post_open',
    <String, Object>{
      'source': _normalize(source),
      'post_id': _normalize(postId),
      'asset_class': _normalize(assetClass),
    },
  );

  static Future<void> logCommunityLikeToggled({
    required String postId,
    required bool liked,
    required String source,
  }) => _log(
    'community_like_toggled',
    <String, Object>{
      'post_id': _normalize(postId),
      'liked': liked,
      'source': _normalize(source),
    },
  );

  static Future<void> logCommunityComposeOpened({
    required String source,
    required String locale,
  }) => _log(
    'community_compose_open',
    <String, Object>{
      'source': _normalize(source),
      'locale': _normalize(locale),
    },
  );

  static Future<void> logCommunityPostSubmitted({
    required bool isEdit,
    required String assetClass,
    required int imageCount,
  }) => _log(
    'community_post_submit',
    <String, Object>{
      'is_edit': isEdit,
      'asset_class': _normalize(assetClass),
      'image_count': _clampCount(imageCount),
    },
  );

  static Future<void> logCommunityReplySubmitted({
    required String assetClass,
  }) => _log(
    'community_reply_submit',
    <String, Object>{
      'asset_class': _normalize(assetClass),
    },
  );

  static Future<void> logHomeView({
    required String locale,
    required String platform,
  }) => _log(
    'home_view',
    <String, Object>{
      'locale': _normalize(locale),
      'platform': _normalize(platform),
      'screen': 'home',
    },
  );

  static Future<void> logCommunityView({
    required String locale,
    required String platform,
  }) => _log(
    'community_view',
    <String, Object>{
      'locale': _normalize(locale),
      'platform': _normalize(platform),
      'screen': 'community',
    },
  );

  static Future<void> logHomeExpandToggle({
    required String sectionId,
    required bool expanded,
    required String locale,
  }) => _log(
    'home_expand_toggle',
    <String, Object>{
      'section_id': _normalize(sectionId),
      'expanded': expanded,
      'locale': _normalize(locale),
    },
  );

  static Future<void> logInterestAdGate({
    required String result,
    required String locale,
  }) => _log(
    'interest_show_more_ad_gate',
    <String, Object>{
      'result': _normalize(result),
      'locale': _normalize(locale),
    },
  );

  static Future<void> logNewsRetryClick({
    required String assetClass,
    required String symbol,
    required String locale,
  }) => _log(
    'news_retry_click',
    <String, Object>{
      'asset_class': _normalize(assetClass),
      'symbol': _normalize(symbol),
      'locale': _normalize(locale),
    },
  );

  static Future<void> logMarketSummaryTranslate({
    required String fromLang,
    required String toLang,
    required String screen,
  }) => _log(
    'market_summary_translate',
    <String, Object>{
      'from_lang': _normalize(fromLang),
      'to_lang': _normalize(toLang),
      'screen': _normalize(screen),
    },
  );

  static Future<void> logPushOpen({
    required String pushType,
    required String source,
    required String platform,
    String? symbol,
    String? assetClass,
  }) => _log(
    'push_open',
    <String, Object>{
      'push_type': _normalize(pushType),
      'source': _normalize(source),
      'platform': _normalize(platform),
      'symbol': _normalize(symbol ?? 'unknown'),
      'asset_class': _normalize(assetClass ?? 'unknown'),
    },
  );

  static Future<void> _log(
    String eventName,
    Map<String, Object> parameters,
  ) async {
    try {
      await _fa.logEvent(name: eventName, parameters: parameters);
      unawaited(BadgeUnlockCenter.instance.trackEvent(eventName, parameters));
    } catch (e) {
      debugPrint('[analytics] logEvent failed ($eventName): $e');
    }
  }

  static int _clampCount(int value) => value < 0 ? 0 : value;

  static String _normalize(String value) {
    final v = value.trim();
    return v.isEmpty ? 'unknown' : v;
  }
}
