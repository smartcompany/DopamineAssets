import 'package:dopamine_assets/core/favorites/favorites_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldApplyFavoritesSyncResult', () {
    test('applies when generation is unchanged', () {
      expect(
        shouldApplyFavoritesSyncResult(
          startedGeneration: 3,
          currentGeneration: 3,
        ),
        isTrue,
      );
    });

    test('rejects after clear() bumps generation', () {
      expect(
        shouldApplyFavoritesSyncResult(
          startedGeneration: 3,
          currentGeneration: 4,
        ),
        isFalse,
      );
    });

    test('rejects any older generation', () {
      expect(
        shouldApplyFavoritesSyncResult(
          startedGeneration: 0,
          currentGeneration: 1,
        ),
        isFalse,
      );
    });
  });

  group('FavoritesCatalog.clear', () {
    test('bumps syncGeneration and empties items', () {
      final catalog = FavoritesCatalog();
      final before = catalog.syncGeneration;
      catalog.clear();
      expect(catalog.syncGeneration, before + 1);
      expect(catalog.items, isEmpty);
      expect(catalog.loading, isFalse);
    });

    test('each clear advances generation so stale syncs stay discarded', () {
      final catalog = FavoritesCatalog();
      catalog.clear();
      final gen = catalog.syncGeneration;
      catalog.clear();
      expect(catalog.syncGeneration, gen + 1);
      expect(
        shouldApplyFavoritesSyncResult(
          startedGeneration: gen,
          currentGeneration: catalog.syncGeneration,
        ),
        isFalse,
      );
    });
  });
}
