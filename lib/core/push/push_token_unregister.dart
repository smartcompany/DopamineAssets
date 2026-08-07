/// Deletes the device FCM token from the server while auth is still valid.
///
/// Returns `true` when [deleteToken] was invoked. Callers should invoke this
/// before Firebase sign-out or account deletion; afterwards the bearer token
/// is gone and the server row would otherwise keep delivering pushes
/// (including market/hot-mover cron traffic) to this device.
Future<bool> unregisterPushTokenIfPossible({
  required Future<String?> Function() resolveIdToken,
  required Future<String?> Function() resolveFcmToken,
  required Future<void> Function({
    required String idToken,
    required String fcmToken,
  })
  deleteToken,
}) async {
  final idToken = await resolveIdToken();
  if (idToken == null || idToken.isEmpty) return false;
  final fcmToken = await resolveFcmToken();
  if (fcmToken == null || fcmToken.isEmpty) return false;
  await deleteToken(idToken: idToken, fcmToken: fcmToken);
  return true;
}
