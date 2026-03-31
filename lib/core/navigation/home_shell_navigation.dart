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

  void openCommunityForAsset({
    required String symbol,
    required String assetClass,
    String? displayName,
  }) {
    _pendingFilter = CommunityNavFilter(
      symbol: symbol,
      assetClass: assetClass,
      displayName: displayName,
    );
    tabIndex = 2;
    notifyListeners();
  }

  /// 한 번만 소비합니다. 리스너에서 호출하세요.
  CommunityNavFilter? takePendingFilter() {
    final f = _pendingFilter;
    _pendingFilter = null;
    return f;
  }

  void setTabIndex(int index) {
    if (tabIndex == index) return;
    tabIndex = index;
    notifyListeners();
  }
}
