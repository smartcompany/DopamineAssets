import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/favorite_asset_item.dart';
import '../../data/models/ranked_asset.dart';
import '../network/dopamine_api.dart';

/// Whether an in-flight favorites sync should apply its result.
///
/// Bumped by [FavoritesCatalog.clear] so a logout/account-switch cannot leave
/// the previous user's watchlist in memory after a late sync completes.
@visibleForTesting
bool shouldApplyFavoritesSyncResult({
  required int startedGeneration,
  required int currentGeneration,
}) =>
    startedGeneration == currentGeneration;

/// 관심 종목 전체 목록 — 탭 전환 때마다 리로드하지 않고,
/// 로그인 시·관심 버튼(토글) 후·당겨서 새로고침 시에만 서버와 동기화합니다.
class FavoritesCatalog extends ChangeNotifier {
  List<FavoriteAssetItem> _items = const [];
  bool _loading = false;

  /// 동시 sync 요청을 직렬화 (대기 후 순차 실행 — 마지막 토글까지 반영).
  Future<void>? _running;

  /// Invalidates in-flight sync applies (and stops further enrichment work).
  int _syncGeneration = 0;

  List<FavoriteAssetItem> get items => _items;
  bool get loading => _loading;

  @visibleForTesting
  int get syncGeneration => _syncGeneration;

  void clear() {
    _syncGeneration++;
    _items = const [];
    _loading = false;
    notifyListeners();
  }

  /// 서버에서 관심 목록 전체를 가져온 뒤, 종목별로 asset-detail로 이름을 보강합니다.
  /// [locale]: ARB와 맞출 앱 로케일(`Localizations.localeOf(context).languageCode`).
  ///
  /// Display-name enrichment is **local only**. Persisting enriched names via
  /// [DopamineApi.upsertFavoriteAsset] during sync can resurrect a favorite the
  /// user deleted while this sync was still walking a stale membership snapshot.
  Future<void> syncFromServer({String? locale}) async {
    final previous = _running;
    final done = Completer<void>();
    _running = done.future;
    if (previous != null) {
      try {
        await previous;
      } catch (_) {}
    }
    try {
      await _syncImpl(locale: locale);
    } finally {
      done.complete();
      if (identical(_running, done.future)) {
        _running = null;
      }
    }
  }

  Future<void> _syncImpl({String? locale}) async {
    final startedGeneration = _syncGeneration;
    _loading = true;
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (shouldApplyFavoritesSyncResult(
          startedGeneration: startedGeneration,
          currentGeneration: _syncGeneration,
        )) {
          _items = const [];
        }
        return;
      }
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        if (shouldApplyFavoritesSyncResult(
          startedGeneration: startedGeneration,
          currentGeneration: _syncGeneration,
        )) {
          _items = const [];
        }
        return;
      }

      final raw = await DopamineApi.fetchFavoriteAssets(idToken: token);
      if (!shouldApplyFavoritesSyncResult(
        startedGeneration: startedGeneration,
        currentGeneration: _syncGeneration,
      )) {
        return;
      }
      if (raw.isEmpty) {
        _items = const [];
        return;
      }

      final out = <FavoriteAssetItem>[];
      for (final item in raw) {
        if (!shouldApplyFavoritesSyncResult(
          startedGeneration: startedGeneration,
          currentGeneration: _syncGeneration,
        )) {
          return;
        }
        try {
          final detail = await DopamineApi.fetchAssetDetail(
            asset: RankedAsset.communityShell(
              symbol: item.symbol,
              assetClass: item.assetClass,
              displayName: item.name,
            ),
            locale: locale,
          );
          final name = detail.name.isEmpty ? item.name : detail.name;
          out.add(
            FavoriteAssetItem(
              symbol: item.symbol,
              assetClass: item.assetClass,
              name: name,
            ),
          );
        } catch (_) {
          out.add(item);
        }
      }
      if (!shouldApplyFavoritesSyncResult(
        startedGeneration: startedGeneration,
        currentGeneration: _syncGeneration,
      )) {
        return;
      }
      _items = out;
    } finally {
      // clear() bumps generation and already resets loading; do not clobber a
      // newer sync that may start after this one leaves the mutex.
      if (shouldApplyFavoritesSyncResult(
        startedGeneration: startedGeneration,
        currentGeneration: _syncGeneration,
      )) {
        _loading = false;
        notifyListeners();
      }
    }
  }
}
