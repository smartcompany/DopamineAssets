import 'package:share_lib/share_lib.dart';

AuthConfig dopamineAuthConfig() {
  return AuthConfig(
    enableKakaoLogin: true,
    enableAppleLogin: true,
    enableGoogleLogin: true,
    enableEmailLogin: true,
    shouldShowProfileSetup: (_) => false,
  );
}
