final class DopamineUser {
  const DopamineUser({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.bio,
    this.suspendedUntil,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;

  /// `dopamine_user_profiles.bio` — 선택, 공개 프로필에 노출 가능.
  final String? bio;

  /// 서버 `dopamine_user_profiles.suspended_until` (ISO8601). 미래 시각이면 정지 중.
  final DateTime? suspendedUntil;

  bool get isAccountSuspended {
    final t = suspendedUntil;
    if (t == null) return false;
    return t.isAfter(DateTime.now());
  }
}
