import 'dart:ui';

import 'package:flutter/foundation.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !kIsWeb) return;
      final q = Uri.base.queryParameters;
      final from = q['from']?.trim();
      final postId = q['postId']?.trim();
      if (from == 'community_share' && postId != null && postId.isNotEmpty) {
        context.read<HomeShellNavigation>().openCommunitySharedPost(
          rootCommentId: postId,
        );
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
