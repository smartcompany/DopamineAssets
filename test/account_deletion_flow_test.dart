import 'package:dopamine_assets/features/profile/account_deletion_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('runAccountDeletionFlow', () {
    test(
      'stops before profile data deletion when auth deletion fails',
      () async {
        final events = <String>[];

        await expectLater(
          runAccountDeletionFlow(
            getIdToken: () async {
              events.add('get-token');
              return 'id-token';
            },
            deleteAuthAccount: () async {
              events.add('delete-auth');
              throw StateError('requires-recent-login');
            },
            deleteProfileData: (idToken) async {
              events.add('delete-profile:$idToken');
            },
            clearLocalConsent: () async {
              events.add('clear-local');
            },
          ),
          throwsA(
            isA<AccountDeletionException>().having(
              (e) => e.step,
              'step',
              AccountDeletionFailureStep.authAccount,
            ),
          ),
        );

        expect(events, <String>['get-token', 'delete-auth']);
      },
    );

    test('deletes profile data only after auth account deletion', () async {
      final events = <String>[];

      await runAccountDeletionFlow(
        getIdToken: () async {
          events.add('get-token');
          return 'id-token';
        },
        deleteAuthAccount: () async {
          events.add('delete-auth');
        },
        deleteProfileData: (idToken) async {
          events.add('delete-profile:$idToken');
        },
        clearLocalConsent: () async {
          events.add('clear-local');
        },
      );

      expect(events, <String>[
        'get-token',
        'delete-auth',
        'delete-profile:id-token',
        'clear-local',
      ]);
    });

    test('stops before deletion when id token is missing', () async {
      final events = <String>[];

      await expectLater(
        runAccountDeletionFlow(
          getIdToken: () async {
            events.add('get-token');
            return '';
          },
          deleteAuthAccount: () async {
            events.add('delete-auth');
          },
          deleteProfileData: (idToken) async {
            events.add('delete-profile:$idToken');
          },
          clearLocalConsent: () async {
            events.add('clear-local');
          },
        ),
        throwsA(
          isA<AccountDeletionException>().having(
            (e) => e.step,
            'step',
            AccountDeletionFailureStep.idToken,
          ),
        ),
      );

      expect(events, <String>['get-token']);
    });
  });
}
