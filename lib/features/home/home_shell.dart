import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/home_shell_navigation.dart';
import '../community/community_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
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
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
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
