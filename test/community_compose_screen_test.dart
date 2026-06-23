import 'package:dopamine_assets/data/models/ranked_asset.dart';
import 'package:dopamine_assets/features/community/community_compose_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('communityComposeSymbolForPost', () {
    test('keeps a selected asset symbol', () {
      expect(
        communityComposeSymbolForPost(
          RankedAsset.communityShell(symbol: 'AAPL', assetClass: 'us_stock'),
        ),
        'AAPL',
      );
    });

    test('does not send the no-symbol UI sentinel to the API', () {
      expect(
        communityComposeSymbolForPost(
          RankedAsset.communityShell(
            symbol: '__none__',
            assetClass: 'us_stock',
          ),
        ),
        isEmpty,
      );
    });
  });
}
