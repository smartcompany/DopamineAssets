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
  bool _hasVisitedCommunity = false;
  CommunityNavFilter? _pendingFilter;
  String? _pendingCommunityRootCommentId;

  bool get hasVisitedCommunity => _hasVisitedCommunity;

  void _markCommunityVisited() {
    _hasVisitedCommunity = true;
  }

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
    _markCommunityVisited();
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
    _markCommunityVisited();
    _pendingFilter = CommunityNavFilter(
      symbol: symbol,
      assetClass: assetClass,
      displayName: displayName,
    );
    _pendingCommunityRootCommentId = rootCommentId;
    tabIndex = 2;
    notifyListeners();
  }

  /// 웹 공유 링크 진입: 특정 커뮤니티 루트 글 상세를 바로 엽니다.
  void openCommunitySharedPost({
    required String rootCommentId,
  }) {
    debugPrint('[UL] nav openCommunitySharedPost id=$rootCommentId');
    _markCommunityVisited();
    _pendingFilter = null;
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
    debugPrint('[UL] nav takePendingCommunityRootCommentId id=$id');
    _pendingCommunityRootCommentId = null;
    return id;
  }

  /// pending 값을 조회만 하고 지우지 않습니다.
  String? peekPendingCommunityRootCommentId() {
    final id = _pendingCommunityRootCommentId;
    debugPrint('[UL] nav peekPendingCommunityRootCommentId id=$id');
    return id;
  }

  /// 특정 id를 실제 처리한 뒤 확정 소비합니다.
  void consumePendingCommunityRootCommentId(String id) {
    if (_pendingCommunityRootCommentId != id) return;
    debugPrint('[UL] nav consumePendingCommunityRootCommentId id=$id');
    _pendingCommunityRootCommentId = null;
  }

  void setTabIndex(int index) {
    if (tabIndex == index) return;
    if (index == 2) _markCommunityVisited();
    tabIndex = index;
    notifyListeners();
  }
}
