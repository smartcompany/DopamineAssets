import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/favorites/favorites_catalog.dart';
import '../../data/models/favorite_asset_item.dart';
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
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    // 첫 이벤트에 현재 로그인 상태가 오므로, 탭을 누를 때마다 리로드하지 않고 여기서만 동기화합니다.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      final c = context.read<FavoritesCatalog>();
      if (user == null) {
        c.clear();
      } else {
        unawaited(c.syncFromServer());
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cat = context.watch<FavoritesCatalog>();

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
          child: Builder(
            builder: (context) {
              final signedIn = FirebaseAuth.instance.currentUser != null;
              if (!signedIn) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      l10n.favoritesSignInToSave,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DopamineTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }
              if (cat.loading && cat.items.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: DopamineTheme.neonGreen),
                );
              }
              final items = cat.items;
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      l10n.favoritesEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DopamineTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }
              final grouped = _groupFavoritesByClass(items);
              final sections = _buildSectionsInOrder(grouped, l10n);
              return RefreshIndicator(
                color: DopamineTheme.neonGreen,
                onRefresh: () => context.read<FavoritesCatalog>().syncFromServer(),
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
