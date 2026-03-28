import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/profile_activity_item.dart';
import '../network/dopamine_api.dart';

/// 프로필 상단 4개 카운트(게시글·팔로잉·팔로워·차단) — 싱글톤.
/// 팔로우/차단 등 동작 후 [refreshWithCurrentFirebaseUser] 로 API와 동기화.
final class ProfileStatsStore extends ChangeNotifier {
  ProfileStatsStore._();
  static final ProfileStatsStore instance = ProfileStatsStore._();

  ProfileStats? _stats;
  ProfileStats? get stats => _stats;

  void apply(ProfileStats next) {
    _stats = next;
    notifyListeners();
  }

  void clear() {
    _stats = null;
    notifyListeners();
  }

  Future<void> refreshFromApi({required String idToken}) async {
    try {
      final s = await DopamineApi.fetchProfileStats(idToken: idToken);
      apply(s);
    } catch (_) {}
  }

  Future<void> refreshWithCurrentFirebaseUser() async {
    final fb = FirebaseAuth.instance.currentUser;
    if (fb == null) return;
    final t = await fb.getIdToken();
    if (t == null || t.isEmpty) return;
    await refreshFromApi(idToken: t);
  }
}
