import 'package:flutter/material.dart';

/// [HomeShell] uses [Scaffold.extendBody], so each tab’s body extends under the
/// bottom [NavigationBar]. Add this to scrollable bottom padding so content is
/// not hidden behind the bar or the system home indicator.
double homeShellBottomInset(BuildContext context) {
  final safe = MediaQuery.viewPaddingOf(context).bottom;
  // Material 3 [NavigationBar] with text labels (~80dp) sits above safe area.
  const navigationBarHeight = 80.0;
  return safe + navigationBarHeight;
}
