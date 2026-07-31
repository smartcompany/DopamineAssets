import 'package:dopamine_assets/core/push/push_prefs_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushPrefsKeys.toApiBody', () {
    test('single-key patch maps only that key to camelCase', () {
      expect(
        PushPrefsKeys.toApiBody({PushPrefsKeys.masterEnabled: false}),
        {'masterEnabled': false},
      );
      expect(
        PushPrefsKeys.toApiBody({PushPrefsKeys.socialReply: true}),
        {'socialReply': true},
      );
    });

    test('full snapshot still maps every provided key', () {
      expect(
        PushPrefsKeys.toApiBody({
          PushPrefsKeys.masterEnabled: false,
          PushPrefsKeys.socialReply: true,
          PushPrefsKeys.socialLike: false,
          PushPrefsKeys.marketDailyBrief: true,
          PushPrefsKeys.hotMoverDiscussion: false,
        }),
        {
          'masterEnabled': false,
          'socialReply': true,
          'socialLike': false,
          'marketDailyBrief': true,
          'hotMoverDiscussion': false,
        },
      );
    });

    test('unknown keys are ignored', () {
      expect(PushPrefsKeys.toApiBody({'not_a_pref': true}), isEmpty);
    });
  });

  group('PushPrefsKeys.shouldApplyFetchedPrefs', () {
    test('applies when epoch matches and no mutation in flight', () {
      expect(
        PushPrefsKeys.shouldApplyFetchedPrefs(
          loadEpoch: 3,
          currentEpoch: 3,
          mutationInFlight: false,
        ),
        isTrue,
      );
    });

    test('rejects stale load epoch after a newer toggle', () {
      expect(
        PushPrefsKeys.shouldApplyFetchedPrefs(
          loadEpoch: 2,
          currentEpoch: 3,
          mutationInFlight: false,
        ),
        isFalse,
      );
    });

    test('rejects loads that overlap an in-flight mutation', () {
      // GET may have started after toggle began but before PATCH committed.
      expect(
        PushPrefsKeys.shouldApplyFetchedPrefs(
          loadEpoch: 4,
          currentEpoch: 4,
          mutationInFlight: true,
        ),
        isFalse,
      );
    });
  });
}
