import 'package:dopamine_assets/data/models/community_post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('community asset symbol helpers', () {
    test('treat empty symbols and the legacy sentinel as no asset', () {
      expect(isCommunityPostWithoutAsset(null), isTrue);
      expect(isCommunityPostWithoutAsset(''), isTrue);
      expect(isCommunityPostWithoutAsset('   '), isTrue);
      expect(isCommunityPostWithoutAsset(communityNoSymbolSentinel), isTrue);
      expect(isCommunityPostWithoutAsset('AAPL'), isFalse);
    });

    test('normalizes no-asset selections before API writes', () {
      expect(communityAssetSymbolForApi(communityNoSymbolSentinel), isEmpty);
      expect(communityAssetSymbolForApi('   '), isEmpty);
      expect(communityAssetSymbolForApi(' AAPL '), 'AAPL');
    });
  });
}
