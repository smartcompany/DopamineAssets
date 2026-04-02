import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import '../../auth/dopamine_user.dart';
import '../../core/navigation/home_shell_navigation.dart';
import '../community/community_screen.dart';
import '../favorites/favorites_screen.dart';
import '../legal/privacy_processing_consent.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AuthProvider<DopamineUser>? _auth;
  bool _consentSessionOk = false;
  bool _consentGateActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachAuth());
  }

  void _attachAuth() {
    if (!mounted) return;
    final auth = context.read<AuthProvider<DopamineUser>>();
    _auth = auth;
    auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final auth = _auth;
    if (auth == null) return;
    if (!auth.isLoggedIn()) {
      _consentSessionOk = false;
      return;
    }
    _schedulePrivacyConsent();
  }

  void _schedulePrivacyConsent() {
    if (_consentSessionOk || _consentGateActive) return;
    // await 전에 반드시 잠금: AuthProvider 가 한 프레임에 여러 번 notify 하면
    // post-frame 콜백이 둘 다 `isPrivacyProcessingConsentAccepted()` await 직전까지 진행해
    // 둘 다 통과하고, 두 번째는 `_dialogActive` 만 보고 false → 로그아웃 되며 동의창이 즉시 닫힌다.
    _consentGateActive = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted || _consentSessionOk) return;
        final auth = context.read<AuthProvider<DopamineUser>>();
        if (!auth.isLoggedIn()) return;
        if (await isPrivacyProcessingConsentAccepted()) {
          if (!mounted) return;
          _consentSessionOk = true;
          return;
        }
        if (!mounted) return;
        final ok = await ensurePrivacyProcessingConsent(context);
        if (!mounted) return;
        if (ok) {
          _consentSessionOk = true;
        } else {
          await auth.logout();
        }
      } finally {
        _consentGateActive = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nav = context.watch<HomeShellNavigation>();

    return Scaffold(
      body: IndexedStack(
        index: nav.tabIndex,
        sizing: StackFit.expand,
        children: const [
          HomeScreen(),
          FavoritesScreen(),
          CommunityScreen(),
          ProfileScreen(),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              selectedIndex: nav.tabIndex,
              onDestinationSelected: nav.setTabIndex,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: l10n.navHome,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.favorite_border_rounded),
                  selectedIcon: const Icon(Icons.favorite_rounded),
                  label: Localizations.localeOf(context).languageCode == 'ko'
                      ? '관심'
                      : 'Favorites',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.forum_outlined),
                  selectedIcon: const Icon(Icons.forum_rounded),
                  label: l10n.navCommunity,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline_rounded),
                  selectedIcon: const Icon(Icons.person_rounded),
                  label: l10n.navProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
