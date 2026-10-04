/// Whether an in-flight load started for [loadUid] at [loadEpoch] may still
/// publish into local state.
///
/// Account switches and sign-out bump [currentEpoch]. Applying the old result
/// after that shows or saves the previous account's data for the new session.
bool accountLoadStillCurrent({
  required bool mounted,
  required int loadEpoch,
  required int currentEpoch,
  required String? loadUid,
  required String? currentUid,
}) {
  if (!mounted) return false;
  if (loadEpoch != currentEpoch) return false;
  if (loadUid == null || loadUid.isEmpty) return false;
  return currentUid == loadUid;
}
