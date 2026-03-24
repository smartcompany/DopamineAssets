import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';

import '../../auth/dopamine_user.dart';
import '../../auth/present_dopamine_auth_screen.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dopamine_api.dart';
import '../../data/models/community_post.dart';
import '../../data/models/ranked_asset.dart';
import '../../theme/dopamine_theme.dart';
import '../asset/asset_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  var _sort = 'latest';
  late Future<List<CommunityPost>> _future = _load();

  Future<List<CommunityPost>> _load() {
    return DopamineApi.fetchCommunityPosts(sort: _sort);
  }

  void _onSort(String next) {
    if (next == _sort) return;
    setState(() {
      _sort = next;
      _future = _load();
    });
  }

  String _classBadge(String assetClass, AppLocalizations l10n) {
    switch (assetClass) {
      case 'us_stock':
        return l10n.assetClassBadgeUsStock;
      case 'kr_stock':
        return l10n.assetClassBadgeKrStock;
      case 'crypto':
        return l10n.assetClassBadgeCrypto;
      case 'commodity':
        return l10n.assetClassBadgeCommodity;
      default:
        return assetClass;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final auth = context.watch<AuthProvider<DopamineUser>>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navCommunity),
        actions: [
          if (!auth.isLoggedIn())
            TextButton(
              onPressed: () => presentDopamineAuthScreen(context),
              child: Text(
                l10n.actionLogin,
                style: const TextStyle(
                  color: DopamineTheme.neonGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: WidgetStateProperty.resolveWith((s) {
                  if (s.contains(WidgetState.selected)) {
                    return DopamineTheme.purpleBottom;
                  }
                  return DopamineTheme.textPrimary;
                }),
                backgroundColor: WidgetStateProperty.resolveWith((s) {
                  if (s.contains(WidgetState.selected)) {
                    return DopamineTheme.neonGreen;
                  }
                  return Colors.white.withValues(alpha: 0.08);
                }),
              ),
              segments: [
                ButtonSegment<String>(
                  value: 'latest',
                  label: Text(l10n.communitySortLatest),
                ),
                ButtonSegment<String>(
                  value: 'popular',
                  label: Text(l10n.communitySortPopular),
                ),
              ],
              selected: <String>{_sort},
              onSelectionChanged: (s) => _onSort(s.first),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CommunityPost>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DopamineTheme.neonGreen,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  final err = snapshot.error;
                  final msg =
                      err is ApiException ? err.message : err.toString();
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            msg,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: DopamineTheme.accentRed,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () {
                              setState(() => _future = _load());
                            },
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final items = snapshot.data ?? const <CommunityPost>[];
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.emptyState,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DopamineTheme.textSecondary,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final p = items[i];
                    final timeStr = DateFormat.yMMMd(locale)
                        .add_jm()
                        .format(p.createdAt.toLocal());
                    return Card(
                      child: InkWell(
                        onTap: () {
                          AssetDetailScreen.open(
                            context,
                            RankedAsset.communityShell(
                              symbol: p.assetSymbol,
                              assetClass: p.assetClass,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DopamineTheme.neonGreen
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: DopamineTheme.neonGreen
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Text(
                                      p.assetSymbol,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: DopamineTheme.neonGreen,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _classBadge(p.assetClass, l10n),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: DopamineTheme.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: DopamineTheme.textSecondary
                                        .withValues(alpha: 0.8),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                p.body,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: DopamineTheme.textPrimary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.authorDisplayName,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: DopamineTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    timeStr,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: DopamineTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              if (p.replyCount > 0) ...[
                                const SizedBox(height: 6),
                                Text(
                                  l10n.communityReplyCount(p.replyCount),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: DopamineTheme.neonGreen
                                        .withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
