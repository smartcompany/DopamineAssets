import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/favorite_asset_item.dart';
import '../../data/models/ranked_asset.dart';
import '../network/dopamine_api.dart';

/// 관심 종목 전체 목록 — 탭 전환 때마다 리로드하지 않고,
/// 로그인 시·관심 버튼(토글) 후·당겨서 새로고침 시에만 서버와 동기화합니다.
class FavoritesCatalog extends ChangeNotifier {
  List<FavoriteAssetItem> _items = const [];
  bool _loading = false;

  /// 동시 sync 요청을 직렬화 (대기 후 순차 실행 — 마지막 토글까지 반영).
  Future<void>? _running;

  List<FavoriteAssetItem> get items => _items;
  bool get loading => _loading;

  void clear() {
    _items = const [];
    _loading = false;
    notifyListeners();
  }

  /// 서버에서 관심 목록 전체를 가져온 뒤, 종목별로 asset-detail로 이름을 보강합니다.
  Future<void> syncFromServer() async {
    while (_running != null) {
      await _running;
    }
    _running = _syncImpl();
    try {
      await _running;
    } finally {
      _running = null;
    }
  }

  Future<void> _syncImpl() async {
    _loading = true;
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _items = const [];
        return;
      }
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        _items = const [];
        return;
      }

      final raw = await DopamineApi.fetchFavoriteAssets(idToken: token);
      if (raw.isEmpty) {
        _items = const [];
        return;
      }

      final out = <FavoriteAssetItem>[];
      for (final item in raw) {
        try {
          final detail = await DopamineApi.fetchAssetDetail(
            asset: RankedAsset.communityShell(
              symbol: item.symbol,
              assetClass: item.assetClass,
              displayName: item.name,
            ),
          );
          final name = detail.name.isEmpty ? item.name : detail.name;
          out.add(
            FavoriteAssetItem(
              symbol: item.symbol,
              assetClass: item.assetClass,
              name: name,
            ),
          );
          if (name != item.name) {
            await DopamineApi.upsertFavoriteAsset(
              idToken: token,
              symbol: item.symbol,
              assetClass: item.assetClass,
              name: name,
            );
          }
        } catch (_) {
          out.add(item);
        }
      }
      _items = out;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
