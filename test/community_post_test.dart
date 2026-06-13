import 'package:dopamine_assets/data/models/community_post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommunityPost.fromRootAssetComment', () {
    test('uses trimmed asset metadata from the root comment', () {
      final post = CommunityPost.fromRootAssetComment(
        id: 'root-1',
        body: 'body',
        authorUid: 'user-1',
        authorDisplayName: 'User',
        createdAt: DateTime.utc(2026),
        assetSymbol: ' TSLA ',
        assetClass: ' us_stock ',
      );

      expect(post.assetSymbol, 'TSLA');
      expect(post.assetClass, 'us_stock');
    });

    test('falls back to navigation asset metadata when root omits it', () {
      final post = CommunityPost.fromRootAssetComment(
        id: 'root-1',
        body: 'body',
        authorUid: 'user-1',
        authorDisplayName: 'User',
        createdAt: DateTime.utc(2026),
        assetSymbol: ' ',
        assetClass: null,
        fallbackAssetSymbol: 'NVDA',
        fallbackAssetClass: 'us_stock',
      );

      expect(post.assetSymbol, 'NVDA');
      expect(post.assetClass, 'us_stock');
    });

    test('rejects roots without usable asset metadata', () {
      expect(
        () => CommunityPost.fromRootAssetComment(
          id: 'root-1',
          body: 'body',
          authorUid: 'user-1',
          authorDisplayName: 'User',
          createdAt: DateTime.utc(2026),
          assetSymbol: null,
          assetClass: ' ',
        ),
        throwsArgumentError,
      );
    });
  });
}
