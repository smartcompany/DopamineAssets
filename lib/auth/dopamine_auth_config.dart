import 'package:flutter/material.dart';
import 'package:share_lib/share_lib.dart';

import '../theme/dopamine_theme.dart';

AuthConfig dopamineAuthConfig() {
  return AuthConfig(
    enableKakaoLogin: true,
    enableAppleLogin: true,
    enableGoogleLogin: true,
    enableEmailLogin: true,
    shouldShowProfileSetup: (_) => false,
  );
}
