import 'package:dopamine_assets/core/feed/thread_root_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveThreadRootCommentId', () {
    test('returns start id when comment is already a root', () async {
      final parents = <String, String?>{
        'root': null,
      };
      final id = await resolveThreadRootCommentId(
        commentId: 'root',
        fetchParentId: (id) async => parents[id],
      );
      expect(id, 'root');
    });

    test('walks a single-level reply to its root', () async {
      final parents = <String, String?>{
        'reply': 'root',
        'root': null,
      };
      final id = await resolveThreadRootCommentId(
        commentId: 'reply',
        fetchParentId: (id) async => parents[id],
      );
      expect(id, 'root');
    });

    test('walks nested replies to the true root', () async {
      final parents = <String, String?>{
        'nested': 'reply',
        'reply': 'root',
        'root': '',
      };
      final id = await resolveThreadRootCommentId(
        commentId: 'nested',
        fetchParentId: (id) async => parents[id],
      );
      expect(id, 'root');
    });

    test('trims whitespace on ids and parent ids', () async {
      final parents = <String, String?>{
        'reply': '  root  ',
        'root': '   ',
      };
      final id = await resolveThreadRootCommentId(
        commentId: '  reply  ',
        fetchParentId: (id) async => parents[id],
      );
      expect(id, 'root');
    });

    test('stops at maxDepth and returns the deepest reached id', () async {
      final parents = <String, String?>{
        'c3': 'c2',
        'c2': 'c1',
        'c1': 'root',
        'root': null,
      };
      final id = await resolveThreadRootCommentId(
        commentId: 'c3',
        fetchParentId: (id) async => parents[id],
        maxDepth: 2,
      );
      // start c3 -> c2 (depth0), c2 -> c1 (depth1) then stop
      expect(id, 'c1');
    });

    test('rejects empty commentId', () async {
      expect(
        () => resolveThreadRootCommentId(
          commentId: '   ',
          fetchParentId: (_) async => null,
        ),
        throwsArgumentError,
      );
    });
  });
}
