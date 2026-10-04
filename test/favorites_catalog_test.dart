import 'dart:async';

import 'package:dopamine_assets/core/favorites/favorites_catalog.dart';
import 'package:dopamine_assets/data/models/favorite_asset_item.dart';
import 'package:flutter_test/flutter_test.dart';

FavoriteAssetItem _item(String symbol, {String name = 'Old'}) {
  return FavoriteAssetItem(symbol: symbol, assetClass: 'us_stock', name: name);
}

void main() {
  test('completed sync publishes the signed-in account favorites', () async {
    final catalog = FavoritesCatalog(
      readUid: () => 'user-a',
      readIdToken: () async => 'token-a',
      fetchFavorites: (_) async => [_item('AAPL', name: 'Apple')],
      resolveDisplayName: (item, _) async => item.name,
      upsertFavorite:
          ({
            required String idToken,
            required String symbol,
            required String assetClass,
            required String name,
          }) async {},
    );

    await catalog.syncFromServer();

    expect(catalog.items.map((e) => e.symbol), ['AAPL']);
    expect(catalog.loading, isFalse);
  });

  test('in-flight sync does not restore favorites after sign-out', () async {
    final fetchStarted = Completer<void>();
    final fetchRelease = Completer<List<FavoriteAssetItem>>();
    final renameStarted = Completer<void>();
    final renameRelease = Completer<void>();
    var upserts = 0;
    String? uid = 'user-a';

    final catalog = FavoritesCatalog(
      readUid: () => uid,
      readIdToken: () async => 'token-a',
      fetchFavorites: (_) {
        if (!fetchStarted.isCompleted) fetchStarted.complete();
        return fetchRelease.future;
      },
      resolveDisplayName: (item, _) async {
        if (!renameStarted.isCompleted) renameStarted.complete();
        await renameRelease.future;
        return 'Renamed ${item.symbol}';
      },
      upsertFavorite:
          ({
            required String idToken,
            required String symbol,
            required String assetClass,
            required String name,
          }) async {
            upserts++;
          },
    );

    final pending = catalog.syncFromServer();
    await fetchStarted.future;
    fetchRelease.complete([_item('AAPL'), _item('TSLA')]);
    await renameStarted.future;

    catalog.clear();
    uid = 'user-b';
    renameRelease.complete();
    await pending;

    expect(catalog.items, isEmpty);
    expect(upserts, 0);
  });

  test(
    'next account does not see the previous account list while loading',
    () async {
      final firstRename = Completer<void>();
      String? uid = 'user-a';
      var phase = 0;
      final secondFetchStarted = Completer<void>();
      final secondFetchRelease = Completer<List<FavoriteAssetItem>>();

      final catalog = FavoritesCatalog(
        readUid: () => uid,
        readIdToken: () async => 'token',
        fetchFavorites: (_) {
          if (phase == 0) {
            return Future<List<FavoriteAssetItem>>.value([_item('AAPL')]);
          }
          if (!secondFetchStarted.isCompleted) secondFetchStarted.complete();
          return secondFetchRelease.future;
        },
        resolveDisplayName: (item, _) async {
          if (phase == 0) {
            await firstRename.future;
          }
          return item.name;
        },
        upsertFavorite:
            ({
              required String idToken,
              required String symbol,
              required String assetClass,
              required String name,
            }) async {},
      );

      final first = catalog.syncFromServer();
      await Future<void>.delayed(Duration.zero);
      catalog.clear();
      uid = 'user-b';
      phase = 1;
      firstRename.complete();
      await first;

      final second = catalog.syncFromServer();
      await secondFetchStarted.future;
      expect(catalog.items, isEmpty);
      expect(catalog.loading, isTrue);

      secondFetchRelease.complete([_item('MSFT', name: 'Microsoft')]);
      await second;
      expect(catalog.items.map((e) => e.symbol), ['MSFT']);
    },
  );
}
