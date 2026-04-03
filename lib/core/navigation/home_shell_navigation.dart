import 'package:flutter/foundation.dart';

/// 홈 셸에서 커뮤니티 탭으로 보낼 때 종목 필터를 전달합니다.
class CommunityNavFilter {
  const CommunityNavFilter({
    required this.symbol,
    required this.assetClass,
    this.displayName,
  });

  final String symbol;
  final String assetClass;
  final String? displayName;
}

class HomeShellNavigation extends ChangeNotifier {
  int tabIndex = 0;
  CommunityNavFilter? _pendingFilter;
  String? _pendingCommunityRootCommentId;

  /// 프로필 등 다른 화면에서 글이 삭제되면 증가시키고, [CommunityScreen]이 목록을 다시 받아옵니다.
  int communityFeedEpoch = 0;

  void bumpCommunityFeedEpoch() {
    communityFeedEpoch++;
    notifyListeners();
  }

  void openCommunityForAsset({
    required String symbol,
    required String assetClass,
    String? displayName,
  }) {
    _pendingCommunityRootCommentId = null;
    _pendingFilter = CommunityNavFilter(
      symbol: symbol,
      assetClass: assetClass,
      displayName: displayName,
    );
    tabIndex = 2;
    notifyListeners();
  }

  /// 급등·급락 토론 푸시: 종목 필터 + 해당 루트 글 상세로 이어집니다.
  void openCommunityHotDiscussion({
    required String symbol,
    required String assetClass,
    required String rootCommentId,
    String? displayName,
  }) {
    _pendingFilter = CommunityNavFilter(
      symbol: symbol,
      assetClass: assetClass,
      displayName: displayName,
    );
    _pendingCommunityRootCommentId = rootCommentId;
    tabIndex = 2;
    notifyListeners();
  }

  /// 한 번만 소비합니다. 리스너에서 호출하세요.
  CommunityNavFilter? takePendingFilter() {
    final f = _pendingFilter;
    _pendingFilter = null;
    return f;
  }

  /// [openCommunityHotDiscussion]와 함께 쓰입니다. 한 번만 소비합니다.
  String? takePendingCommunityRootCommentId() {
    final id = _pendingCommunityRootCommentId;
    _pendingCommunityRootCommentId = null;
    return id;
  }

  void setTabIndex(int index) {
    if (tabIndex == index) return;
    tabIndex = index;
    notifyListeners();
  }
}
