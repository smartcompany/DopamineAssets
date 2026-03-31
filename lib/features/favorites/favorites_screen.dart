import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/home_shell_navigation.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/favorite_assets_prefs.dart';
import '../../data/models/ranked_asset.dart';
import '../../theme/dopamine_theme.dart';
import '../asset/asset_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<FavoriteAssetItem>> _future = _load();
  HomeShellNavigation? _shellNav;
  int _prevShellTabIndex = 0;

  Future<List<FavoriteAssetItem>> _load() async {
    final items = await FavoriteAssetsPrefs.load();
    if (items.isEmpty) return items;
    final out = <FavoriteAssetItem>[];
    for (final item in items) {
      try {
        final detail = await DopamineApi.fetchAssetDetail(
          asset: RankedAsset.communityShell(
            symbol: item.symbol,
            assetClass: item.assetClass,
            displayName: item.name,
          ),
        );
        out.add(
          FavoriteAssetItem(
            symbol: item.symbol,
            assetClass: item.assetClass,
            name: detail.name.isEmpty ? item.name : detail.name,
          ),
        );
      } catch (_) {
        out.add(item);
      }
    }
    await FavoriteAssetsPrefs.save(out);
    return out;
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
  }

  void _handleShellNav() {
    final nav = _shellNav;
    if (nav == null || !mounted) return;
    final t = nav.tabIndex;
    if (t == 1 && _prevShellTabIndex != 1) {
      _reload();
    }
    _prevShellTabIndex = t;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<HomeShellNavigation>();
    if (!identical(_shellNav, nav)) {
      _shellNav?.removeListener(_handleShellNav);
      _shellNav = nav;
      _prevShellTabIndex = nav.tabIndex;
      _shellNav!.addListener(_handleShellNav);
    }
  }

  @override
  void dispose() {
    _shellNav?.removeListener(_handleShellNav);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [DopamineTheme.purpleTop, DopamineTheme.purpleBottom],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<FavoriteAssetItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: DopamineTheme.neonGreen),
                );
              }
              final items = snapshot.data ?? const <FavoriteAssetItem>[];
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    '관심 자산이 없습니다.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DopamineTheme.textSecondary,
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Material(
                      color: Colors.black.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          AssetDetailScreen.open(
                            context,
                            RankedAsset.communityShell(
                              symbol: item.symbol,
                              assetClass: item.assetClass,
                              displayName: item.name,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                color: DopamineTheme.neonGreen,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name.isEmpty ? item.symbol : item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: DopamineTheme.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.symbol} · ${item.assetClass}',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: DopamineTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: DopamineTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
