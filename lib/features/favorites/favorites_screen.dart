import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/home_shell_navigation.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/favorite_assets_prefs.dart';
import '../../data/models/ranked_asset.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
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
              final grouped = _groupFavoritesByClass(items);
              final sections = _buildSectionsInOrder(grouped, l10n);
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: index == sections.length - 1 ? 0 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 2, bottom: 8),
                            child: Text(
                              section.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: DopamineTheme.neonGreen,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          ...section.items.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _FavoriteItemTile(
                                  item: item,
                                  classLabel: _classLabel(item.assetClass, l10n),
                                  onOpen: () async {
                                    await AssetDetailScreen.open(
                                      context,
                                      RankedAsset.communityShell(
                                        symbol: item.symbol,
                                        assetClass: item.assetClass,
                                        displayName: item.name,
                                      ),
                                    );
                                    if (!mounted) return;
                                    _reload();
                                  },
                                ),
                              )),
                        ],
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

Map<String, List<FavoriteAssetItem>> _groupFavoritesByClass(
  List<FavoriteAssetItem> items,
) {
  final out = <String, List<FavoriteAssetItem>>{};
  for (final item in items) {
    final key = item.assetClass.trim().toLowerCase();
    out.putIfAbsent(key, () => <FavoriteAssetItem>[]).add(item);
  }
  return out;
}

List<_FavoriteSection> _buildSectionsInOrder(
  Map<String, List<FavoriteAssetItem>> grouped,
  AppLocalizations l10n,
) {
  final order = <({String key, String title})>[
    (key: 'kr_stock', title: l10n.assetClassBadgeKrStock),
    (key: 'us_stock', title: l10n.assetClassBadgeUsStock),
    (key: 'crypto', title: l10n.assetClassBadgeCrypto),
    (key: 'commodity', title: l10n.assetClassBadgeCommodity),
  ];
  final out = <_FavoriteSection>[];
  for (final o in order) {
    final list = grouped[o.key];
    if (list == null || list.isEmpty) continue;
    out.add(_FavoriteSection(title: o.title, items: list));
  }
  return out;
}

String _classLabel(String assetClass, AppLocalizations l10n) {
  switch (assetClass.trim().toLowerCase()) {
    case 'kr_stock':
      return l10n.assetClassBadgeKrStock;
    case 'us_stock':
      return l10n.assetClassBadgeUsStock;
    case 'crypto':
      return l10n.assetClassBadgeCrypto;
    case 'commodity':
      return l10n.assetClassBadgeCommodity;
    case 'theme':
      return l10n.assetClassBadgeTheme;
    default:
      return assetClass;
  }
}

final class _FavoriteSection {
  const _FavoriteSection({required this.title, required this.items});

  final String title;
  final List<FavoriteAssetItem> items;
}

class _FavoriteItemTile extends StatelessWidget {
  const _FavoriteItemTile({
    required this.item,
    required this.classLabel,
    required this.onOpen,
  });

  final FavoriteAssetItem item;
  final String classLabel;
  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.black.withValues(alpha: 0.24),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      '${item.symbol} · $classLabel',
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
  }
}
