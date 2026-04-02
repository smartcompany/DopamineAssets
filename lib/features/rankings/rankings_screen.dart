import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';

import '../../core/network/dopamine_api.dart';
import '../../data/ranking_filter_prefs.dart';
import '../../data/models/ranked_asset.dart';
import '../../widgets/async_body.dart';
import '../../widgets/ranked_asset_tile.dart';
import '../asset/asset_detail_screen.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Future<List<RankedAsset>> _upFuture;
  late final Future<List<RankedAsset>> _downFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final classesFuture = RankingFilterPrefs.load();
    final loc = PlatformDispatcher.instance.locale.languageCode;
    _upFuture = classesFuture.then(
      (c) => DopamineApi.fetchRankingsUp(
        includeAssetClasses: c,
        locale: loc,
      ),
    );
    _downFuture = classesFuture.then(
      (c) => DopamineApi.fetchRankingsDown(
        includeAssetClasses: c,
        locale: loc,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navRankings),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.rankingsUpTab),
            Tab(text: l10n.rankingsDownTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RankingsList(future: _upFuture),
          _RankingsList(future: _downFuture),
        ],
      ),
    );
  }
}

class _RankingsList extends StatelessWidget {
  const _RankingsList({required this.future});

  final Future<List<RankedAsset>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RankedAsset>>(
      future: future,
      builder: (context, snapshot) {
        return buildAsyncBody<List<RankedAsset>>(
          context: context,
          snapshot: snapshot,
          onData: (context, items) {
            if (items.isEmpty) {
              final l10n = AppLocalizations.of(context)!;
              return Center(child: Text(l10n.emptyState));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return RankedAssetTile(
                  rank: index + 1,
                  asset: items[index],
                  onTap: () => AssetDetailScreen.open(context, items[index]),
                );
              },
            );
          },
        );
      },
    );
  }
}
