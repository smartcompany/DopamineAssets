import 'package:dopamine_assets/data/models/ranked_asset.dart';
import 'package:dopamine_assets/features/community/community_compose_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('concreteCommunityPostTarget', () {
    test('normalizes valid post targets', () {
      expect(
        concreteCommunityPostTarget(
          symbol: ' AAPL ',
          assetClass: ' us_stock ',
        ),
        (symbol: 'AAPL', assetClass: 'us_stock'),
      );
    });

    test('rejects placeholder post targets', () {
      expect(
        concreteCommunityPostTarget(
          symbol: communityComposeNoSymbolSentinel,
          assetClass: 'us_stock',
        ),
        isNull,
      );
    });
  });

  group('isConcreteCommunityComposeSelection', () {
    test('rejects no-selection placeholders', () {
      expect(isConcreteCommunityComposeSelection(null), isFalse);
      expect(
        isConcreteCommunityComposeSelection(
          RankedAsset.communityShell(
            symbol: communityComposeNoSymbolSentinel,
            assetClass: 'us_stock',
          ),
        ),
        isFalse,
      );
    });

    test('rejects incomplete asset selections', () {
      const emptySymbol = RankedAsset(
        symbol: '',
        name: '',
        priceChangePct: 0,
        volumeChangePct: 0,
        dopamineScore: 0,
        assetClass: 'us_stock',
      );
      const emptyAssetClass = RankedAsset(
        symbol: 'AAPL',
        name: 'Apple',
        priceChangePct: 0,
        volumeChangePct: 0,
        dopamineScore: 0,
        assetClass: '',
      );

      expect(isConcreteCommunityComposeSelection(emptySymbol), isFalse);
      expect(isConcreteCommunityComposeSelection(emptyAssetClass), isFalse);
    });

    test('accepts a real symbol and asset class', () {
      expect(
        isConcreteCommunityComposeSelection(
          RankedAsset.communityShell(
            symbol: 'AAPL',
            assetClass: 'us_stock',
            displayName: 'Apple',
          ),
        ),
        isTrue,
      );
    });
  });
}
