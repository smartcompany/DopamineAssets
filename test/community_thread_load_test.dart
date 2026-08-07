import 'package:dopamine_assets/core/feed/community_thread_load.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isCurrentThreadLoad', () {
    test('accepts matching generation', () {
      expect(isCurrentThreadLoad(gen: 3, currentGen: 3), isTrue);
    });

    test('rejects stale generation', () {
      expect(isCurrentThreadLoad(gen: 2, currentGen: 3), isFalse);
    });
  });

  group('reconcileReplyParentId', () {
    test('keeps null', () {
      expect(
        reconcileReplyParentId(
          replyParentId: null,
          rootId: 'root',
          threadIds: {'root', 'a'},
        ),
        isNull,
      );
    });

    test('keeps root parent even if only root is listed', () {
      expect(
        reconcileReplyParentId(
          replyParentId: 'root',
          rootId: 'root',
          threadIds: {'root'},
        ),
        'root',
      );
    });

    test('keeps parent still present in thread', () {
      expect(
        reconcileReplyParentId(
          replyParentId: 'c1',
          rootId: 'root',
          threadIds: {'root', 'c1'},
        ),
        'c1',
      );
    });

    test('clears parent missing from thread', () {
      expect(
        reconcileReplyParentId(
          replyParentId: 'deleted',
          rootId: 'root',
          threadIds: {'root', 'c1'},
        ),
        isNull,
      );
    });
  });
}
