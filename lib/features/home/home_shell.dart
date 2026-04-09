import 'dart:ui';
import 'dart:async';

import 'package:app_links/app_links.dart';
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

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  AuthProvider<DopamineUser>? _auth;
  bool _consentSessionOk = false;
  bool _consentGateActive = false;
  StreamSubscription<Uri>? _deepLinkSub;
  Uri? _lastConsumedUri;
  DateTime? _lastConsumedAt;
  bool _deepLinkRoutingInProgress = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  Uri? _pendingDeepLinkUri;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('[UL] HomeShell.initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      debugPrint('[UL] postFrame uri.base=${Uri.base}');
      _consumeOrQueueShareUri(Uri.base);
      if (!kIsWeb) {
        debugPrint('[UL] bind incoming deep links');
        _bindIncomingDeepLinks();
      }
    });
  }

  void _consumeOrQueueShareUri(Uri uri) {
    if (!kIsWeb && _lifecycleState != AppLifecycleState.resumed) {
      _pendingDeepLinkUri = uri;
      debugPrint('[UL] queued uri while lifecycle=$_lifecycleState uri=$uri');
      return;
    }
    _consumeShareUri(uri);
  }

  void _consumeShareUri(Uri uri) {
    final now = DateTime.now();
    if (_lastConsumedUri?.toString() == uri.toString() &&
        _lastConsumedAt != null &&
        now.difference(_lastConsumedAt!).inSeconds < 3) {
      debugPrint('[UL] dedupe skip uri=$uri');
      return;
    }
    if (_deepLinkRoutingInProgress) {
      debugPrint('[UL] routing in-progress skip uri=$uri');
      return;
    }
    _lastConsumedUri = uri;
    _lastConsumedAt = now;
    debugPrint('[UL] consume uri=$uri');
    final path = uri.path.toLowerCase();
    final q = uri.queryParameters;
    final segments = uri.pathSegments;
    final ulPostId = (segments.length >= 2 && segments[0].toLowerCase() == '_ul')
        ? segments[1].trim()
        : null;
    final pathPostId = (segments.length >= 3 &&
            segments[0].toLowerCase() == 'community' &&
            segments[1].toLowerCase() == 'share')
        ? segments[2].trim()
        : null;
    final postId = (ulPostId?.isNotEmpty ?? false)
        ? ulPostId
        : (pathPostId?.isNotEmpty ?? false)
        ? pathPostId
        : q['postId']?.trim();
    final isCommunitySharePath =
        path == '/community/share' || pathPostId != null || ulPostId != null;
    final isLegacyCommunityShare = (q['from']?.trim() ?? '') == 'community_share';
    debugPrint(
      '[UL] parsed path=$path postId=$postId communityPath=$isCommunitySharePath legacy=$isLegacyCommunityShare',
    );
    if ((isCommunitySharePath || isLegacyCommunityShare) &&
        postId != null &&
        postId.isNotEmpty) {
      _deepLinkRoutingInProgress = true;
      debugPrint('[UL] openCommunitySharedPost id=$postId');
      context.read<HomeShellNavigation>().openCommunitySharedPost(
            rootCommentId: postId,
          );
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        _deepLinkRoutingInProgress = false;
        debugPrint('[UL] routing lock released');
      });
    } else {
      debugPrint('[UL] ignored uri');
    }
  }

  Future<void> _bindIncomingDeepLinks() async {
    try {
      final appLinks = AppLinks();
      final initial = await appLinks.getInitialLink();
      debugPrint('[UL] app_links initial=$initial');
      if (mounted && initial != null) {
        _consumeOrQueueShareUri(initial);
      }
      _deepLinkSub = appLinks.uriLinkStream.listen((uri) {
        if (!mounted) return;
        debugPrint('[UL] app_links stream uri=$uri');
        _consumeOrQueueShareUri(uri);
      });
    } catch (_) {
      // Deep link plugin is best-effort; ignore and keep normal navigation.
      debugPrint('[UL] app_links bind failed');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prev = _lifecycleState;
    _lifecycleState = state;
    debugPrint('[UL] lifecycle=$state');
    if (!kIsWeb &&
        state == AppLifecycleState.resumed &&
        _pendingDeepLinkUri != null) {
      final pending = _pendingDeepLinkUri!;
      _pendingDeepLinkUri = null;
      debugPrint('[UL] draining queued uri after resumed uri=$pending (prev=$prev)');
      _consumeShareUri(pending);
    }
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
