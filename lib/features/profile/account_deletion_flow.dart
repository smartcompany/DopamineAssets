enum AccountDeletionFailureStep {
  idToken,
  authAccount,
  profileData,
  localCleanup,
}

final class AccountDeletionException implements Exception {
  const AccountDeletionException({
    required this.step,
    required this.cause,
    required this.stackTrace,
  });

  final AccountDeletionFailureStep step;
  final Object cause;
  final StackTrace stackTrace;

  @override
  String toString() => 'AccountDeletionException($step, $cause)';
}

typedef AccountDeletionDebugLog = void Function(String message);

Future<void> runAccountDeletionFlow({
  required Future<String?> Function() getIdToken,
  required Future<void> Function() deleteAuthAccount,
  required Future<void> Function(String idToken) deleteProfileData,
  required Future<void> Function() clearLocalConsent,
  AccountDeletionDebugLog? debugLog,
  String? uidForLog,
}) async {
  final String token;
  try {
    final value = await getIdToken();
    if (value == null || value.isEmpty) {
      throw StateError('invalid-id-token');
    }
    token = value;
  } catch (e, st) {
    throw AccountDeletionException(
      step: AccountDeletionFailureStep.idToken,
      cause: e,
      stackTrace: st,
    );
  }

  try {
    await deleteAuthAccount();
  } catch (e, st) {
    throw AccountDeletionException(
      step: AccountDeletionFailureStep.authAccount,
      cause: e,
      stackTrace: st,
    );
  }

  debugLog?.call(
    '[Dopamine][delete-account] request /api/profile/me '
    'uid=${uidForLog ?? "unknown"} tokenLen=${token.length}',
  );

  try {
    await deleteProfileData(token);
  } catch (e, st) {
    throw AccountDeletionException(
      step: AccountDeletionFailureStep.profileData,
      cause: e,
      stackTrace: st,
    );
  }

  try {
    await clearLocalConsent();
  } catch (e, st) {
    throw AccountDeletionException(
      step: AccountDeletionFailureStep.localCleanup,
      cause: e,
      stackTrace: st,
    );
  }
}
