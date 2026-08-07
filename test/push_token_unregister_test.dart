import 'package:dopamine_assets/core/push/push_token_unregister.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('unregisterPushTokenIfPossible', () {
    test('deletes when id token and fcm token are present', () async {
      String? deletedId;
      String? deletedFcm;
      final did = await unregisterPushTokenIfPossible(
        resolveIdToken: () async => 'id-token',
        resolveFcmToken: () async => 'fcm-token-value',
        deleteToken: ({required idToken, required fcmToken}) async {
          deletedId = idToken;
          deletedFcm = fcmToken;
        },
      );
      expect(did, isTrue);
      expect(deletedId, 'id-token');
      expect(deletedFcm, 'fcm-token-value');
    });

    test('skips delete when id token missing', () async {
      var deleted = false;
      final did = await unregisterPushTokenIfPossible(
        resolveIdToken: () async => null,
        resolveFcmToken: () async => 'fcm-token-value',
        deleteToken: ({required idToken, required fcmToken}) async {
          deleted = true;
        },
      );
      expect(did, isFalse);
      expect(deleted, isFalse);
    });

    test('skips delete when id token empty', () async {
      var deleted = false;
      final did = await unregisterPushTokenIfPossible(
        resolveIdToken: () async => '',
        resolveFcmToken: () async => 'fcm-token-value',
        deleteToken: ({required idToken, required fcmToken}) async {
          deleted = true;
        },
      );
      expect(did, isFalse);
      expect(deleted, isFalse);
    });

    test('skips delete when fcm token missing', () async {
      var deleted = false;
      final did = await unregisterPushTokenIfPossible(
        resolveIdToken: () async => 'id-token',
        resolveFcmToken: () async => null,
        deleteToken: ({required idToken, required fcmToken}) async {
          deleted = true;
        },
      );
      expect(did, isFalse);
      expect(deleted, isFalse);
    });

    test('skips delete when fcm token empty', () async {
      var deleted = false;
      final did = await unregisterPushTokenIfPossible(
        resolveIdToken: () async => 'id-token',
        resolveFcmToken: () async => '',
        deleteToken: ({required idToken, required fcmToken}) async {
          deleted = true;
        },
      );
      expect(did, isFalse);
      expect(deleted, isFalse);
    });

    test('propagates deleteToken errors to caller', () async {
      expect(
        () => unregisterPushTokenIfPossible(
          resolveIdToken: () async => 'id-token',
          resolveFcmToken: () async => 'fcm-token-value',
          deleteToken: ({required idToken, required fcmToken}) async {
            throw StateError('network');
          },
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
