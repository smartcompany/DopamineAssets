import 'package:flutter/material.dart';
import 'package:share_lib/share_lib.dart';

import '../theme/dopamine_theme.dart';

AuthConfig dopamineAuthConfig() {
  return AuthConfig(
    primaryColor: DopamineTheme.neonGreen,
    textPrimaryColor: DopamineTheme.textPrimary,
    textSecondaryColor: DopamineTheme.textSecondary,
    textTertiaryColor: DopamineTheme.textSecondary.withValues(alpha: 0.85),
    dividerColor: Colors.white.withValues(alpha: 0.14),
    backgroundColor: DopamineTheme.scaffoldBase,
    enableKakaoLogin: false,
    enableAppleLogin: true,
    enableGoogleLogin: true,
    enableEmailLogin: true,
    shouldShowProfileSetup: (_) => false,
  );
}
