import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/favorite_asset_item.dart';
import '../../data/models/ranked_asset.dart';
import '../network/dopamine_api.dart';

/// 관심 종목 전체 목록 — 탭 전환 때마다 리로드하지 않고,
/// 로그인 시·관심 버튼(토글) 후·당겨서 새로고침 시에만 서버와 동기화합니다.
class FavoritesCatalog extends ChangeNotifier {
  FavoritesCatalog({
    String? Function()? readUid,
    Future<String?> Function()? readIdToken,
    Future<List<FavoriteAssetItem>> Function(String idToken)? fetchFavorites,
    Future<String> Function(FavoriteAssetItem item, String? locale)?
    resolveDisplayName,
    Future<void> Function({
      required String idToken,
      required String symbol,
      required String assetClass,
      required String name,
    })?
    upsertFavorite,
  }) : _readUid = readUid ?? _firebaseUid,
       _readIdToken = readIdToken ?? _firebaseIdToken,
       _fetchFavorites = fetchFavorites ?? _defaultFetchFavorites,
       _resolveDisplayName = resolveDisplayName ?? _defaultResolveDisplayName,
       _upsertFavorite = upsertFavorite ?? _defaultUpsertFavorite;

  final String? Function() _readUid;
  final Future<String?> Function() _readIdToken;
  final Future<List<FavoriteAssetItem>> Function(String idToken)
  _fetchFavorites;
  final Future<String> Function(FavoriteAssetItem item, String? locale)
  _resolveDisplayName;
  final Future<void> Function({
    required String idToken,
    required String symbol,
    required String assetClass,
    required String name,
  })
  _upsertFavorite;

  List<FavoriteAssetItem> _items = const [];
  bool _loading = false;

  /// 동시 sync 요청을 직렬화 (대기 후 순차 실행 — 마지막 토글까지 반영).
  Future<void>? _running;

  /// [clear] (로그아웃) 때마다 증가. 진행 중인 sync가 이전 계정의 목록을
  /// 다시 쓰지 못하게 합니다.
  int _generation = 0;

  List<FavoriteAssetItem> get items => _items;
  bool get loading => _loading;

  void clear() {
    _generation++;
    _items = const [];
    _loading = false;
    notifyListeners();
  }

  /// 서버에서 관심 목록 전체를 가져온 뒤, 종목별로 asset-detail로 이름을 보강합니다.
  /// [locale]: ARB와 맞출 앱 로케일(`Localizations.localeOf(context).languageCode`).
  Future<void> syncFromServer({String? locale}) async {
    while (_running != null) {
      await _running;
    }
    _running = _syncImpl(locale: locale);
    try {
      await _running;
    } finally {
      _running = null;
    }
  }

  bool _stale(int generation, String? uid) =>
      generation != _generation || _readUid() != uid;

  Future<void> _syncImpl({String? locale}) async {
    final generation = _generation;
    final uid = _readUid();
    _loading = true;
    notifyListeners();
    try {
      if (_stale(generation, uid)) return;
      if (uid == null) {
        _items = const [];
        return;
      }
      final token = await _readIdToken();
      if (_stale(generation, uid)) return;
      if (token == null || token.isEmpty) {
        _items = const [];
        return;
      }

      final raw = await _fetchFavorites(token);
      if (_stale(generation, uid)) return;
      if (raw.isEmpty) {
        _items = const [];
        return;
      }

      final out = <FavoriteAssetItem>[];
      for (final item in raw) {
        if (_stale(generation, uid)) return;
        try {
          final name = await _resolveDisplayName(item, locale);
          if (_stale(generation, uid)) return;
          out.add(
            FavoriteAssetItem(
              symbol: item.symbol,
              assetClass: item.assetClass,
              name: name,
            ),
          );
          if (name != item.name) {
            await _upsertFavorite(
              idToken: token,
              symbol: item.symbol,
              assetClass: item.assetClass,
              name: name,
            );
            if (_stale(generation, uid)) return;
          }
        } catch (_) {
          if (_stale(generation, uid)) return;
          out.add(item);
        }
      }
      if (_stale(generation, uid)) return;
      _items = out;
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  static String? _firebaseUid() => FirebaseAuth.instance.currentUser?.uid;

  static Future<String?> _firebaseIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  static Future<List<FavoriteAssetItem>> _defaultFetchFavorites(
    String idToken,
  ) {
    return DopamineApi.fetchFavoriteAssets(idToken: idToken);
  }

  static Future<String> _defaultResolveDisplayName(
    FavoriteAssetItem item,
    String? locale,
  ) async {
    final detail = await DopamineApi.fetchAssetDetail(
      asset: RankedAsset.communityShell(
        symbol: item.symbol,
        assetClass: item.assetClass,
        displayName: item.name,
      ),
      locale: locale,
    );
    return detail.name.isEmpty ? item.name : detail.name;
  }

  static Future<void> _defaultUpsertFavorite({
    required String idToken,
    required String symbol,
    required String assetClass,
    required String name,
  }) {
    return DopamineApi.upsertFavoriteAsset(
      idToken: idToken,
      symbol: symbol,
      assetClass: assetClass,
      name: name,
    );
  }
}
