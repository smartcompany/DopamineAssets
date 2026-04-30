import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../core/badges/badge_unlock_center.dart';
import '../../core/navigation/home_shell_navigation.dart';
import '../../theme/dopamine_theme.dart';
import '../community/community_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

enum _NudgeType { profile, community }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialSharedPostId});

  final String? initialSharedPostId;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  bool _profileTooltipShown = false;
  bool _communityTooltipShown = false;
  bool _showProfileNudge = false;
  bool _showCommunityNudge = false;
  Timer? _nudgeTimer;
  Timer? _badgeToastTimer;
  BadgeUnlockToast? _badgeToast;

  void _handleBadgeUnlockCenter() {
    final toast = BadgeUnlockCenter.instance.pendingToast;
    if (toast == null) return;
    _badgeToastTimer?.cancel();
    setState(() => _badgeToast = toast);
    BadgeUnlockCenter.instance.clearToast();
    _badgeToastTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _badgeToast = null);
    });
  }

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[UL][home] initState initialSharedPostId=${widget.initialSharedPostId}',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusCommunityTabIfNeeded();
      _scheduleNextNudge();
    });
    BadgeUnlockCenter.instance.addListener(_handleBadgeUnlockCenter);
    unawaited(BadgeUnlockCenter.instance.ensureInitialized());
  }

  void _scheduleNextNudge() {
    final nav = context.read<HomeShellNavigation>();
    if (nav.tabIndex != 0) return;
    if (_showProfileNudge || _showCommunityNudge) return;
    final signedIn = FirebaseAuth.instance.currentUser != null;

    _NudgeType? next;
    if (!signedIn && !_profileTooltipShown) {
      next = _NudgeType.profile;
    } else if (!_communityTooltipShown) {
      next = _NudgeType.community;
    }
    if (next == null) return;

    _nudgeTimer?.cancel();
    _nudgeTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      final navNow = context.read<HomeShellNavigation>();
      if (navNow.tabIndex != 0) return;
      final signedInNow = FirebaseAuth.instance.currentUser != null;
      setState(() {
        if (next == _NudgeType.profile && !signedInNow && !_profileTooltipShown) {
          _profileTooltipShown = true;
          _showProfileNudge = true;
          _showCommunityNudge = false;
        } else if (next == _NudgeType.community && !_communityTooltipShown) {
          _communityTooltipShown = true;
          _showCommunityNudge = true;
          _showProfileNudge = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    _badgeToastTimer?.cancel();
    BadgeUnlockCenter.instance.removeListener(_handleBadgeUnlockCenter);
    super.dispose();
  }

  void _dismissProfileNudge() {
    if (!mounted) return;
    setState(() => _showProfileNudge = false);
    _scheduleNextNudge();
  }

  void _dismissCommunityNudge() {
    if (!mounted) return;
    setState(() => _showCommunityNudge = false);
  }

  Widget _buildBubble({
    required String text,
    required double right,
    required VoidCallback onTapBubble,
    required VoidCallback onTapClose,
    required double tailRight,
  }) {
    return Positioned(
      right: right,
      bottom: 92 + MediaQuery.of(context).padding.bottom,
      child: GestureDetector(
        onTap: onTapBubble,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 230),
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3B0),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Color(0xFF3B1D00),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onTapClose,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Color(0xFF7C2D12),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: tailRight),
              child: CustomPaint(
                size: const Size(16, 10),
                painter: _BubbleTailPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNudgeBubble() {
    final l10n = AppLocalizations.of(context)!;
    return _buildBubble(
      text: l10n.homeProfileNudge,
      right: 12,
      tailRight: 18,
      onTapBubble: _dismissProfileNudge,
      onTapClose: _dismissProfileNudge,
    );
  }

  Widget _buildCommunityNudgeBubble() {
    final l10n = AppLocalizations.of(context)!;
    return _buildBubble(
      text: l10n.homeCommunityNudge,
      right: 74,
      tailRight: 66,
      onTapBubble: () {
        context.read<HomeShellNavigation>().setTabIndex(2);
        _dismissCommunityNudge();
      },
      onTapClose: _dismissCommunityNudge,
    );
  }

  Widget _buildBadgeUnlockToast() {
    final toast = _badgeToast;
    if (toast == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      top: 14 + MediaQuery.of(context).padding.top,
      left: 14,
      right: 14,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFF111827).withValues(alpha: 0.96),
            border: Border.all(
              color: const Color(0xFF34D399).withValues(alpha: 0.6),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (toast.imagePath.startsWith('http://') ||
                        toast.imagePath.startsWith('https://'))
                    ? Image.network(
                        toast.imagePath,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 42,
                        height: 42,
                        color: Colors.white.withValues(alpha: 0.08),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: DopamineTheme.neonGreen.withValues(alpha: 0.85),
                          size: 26,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.profileBadgeToastUnlocked,
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      toast.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _badgeToast = null),
                icon: const Icon(Icons.close_rounded, size: 18),
                color: Colors.white70,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint(
      '[UL][home] didUpdate old=${oldWidget.initialSharedPostId} new=${widget.initialSharedPostId}',
    );
    if (oldWidget.initialSharedPostId != widget.initialSharedPostId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusCommunityTabIfNeeded();
      });
    }
  }

  void _focusCommunityTabIfNeeded() {
    final postId = widget.initialSharedPostId?.trim();
    debugPrint(
      '[UL][home] focus check initialSharedPostId=${widget.initialSharedPostId} normalized=$postId',
    );
    if (postId == null || postId.isEmpty) return;
    debugPrint('[UL][home] move to community tab for shared post id=$postId');
    context.read<HomeShellNavigation>().setTabIndex(2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nav = context.watch<HomeShellNavigation>();
    final signedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: nav.tabIndex,
            sizing: StackFit.expand,
            children: [
              const HomeScreen(),
              const FavoritesScreen(),
              CommunityScreen(initialSharedPostId: widget.initialSharedPostId),
              const ProfileScreen(),
            ],
          ),
          if (!signedIn && _showProfileNudge && nav.tabIndex == 0)
            _buildProfileNudgeBubble(),
          if (_showCommunityNudge && nav.tabIndex == 0)
            _buildCommunityNudgeBubble(),
          if (_badgeToast != null) _buildBadgeUnlockToast(),
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
              onDestinationSelected: (index) {
                if (index == 3) {
                  setState(() {
                    _profileTooltipShown = true;
                    _showProfileNudge = false;
                    _showCommunityNudge = false;
                  });
                  _nudgeTimer?.cancel();
                } else if (index == 2) {
                  setState(() {
                    _communityTooltipShown = true;
                    _showProfileNudge = false;
                    _showCommunityNudge = false;
                  });
                  _nudgeTimer?.cancel();
                }
                nav.setTabIndex(index);
                if (index == 0) {
                  _scheduleNextNudge();
                } else {
                  setState(() {
                    _showProfileNudge = false;
                    _showCommunityNudge = false;
                  });
                  _nudgeTimer?.cancel();
                }
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: l10n.navHome,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.favorite_border_rounded),
                  selectedIcon: const Icon(Icons.favorite_rounded),
                  label: l10n.navFavorites,
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

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFF3B0);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
