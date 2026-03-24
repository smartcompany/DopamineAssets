import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';

import '../core/formatting/percent_format.dart';
import '../data/models/ranked_asset.dart';

class RankedAssetTile extends StatelessWidget {
  const RankedAssetTile({
    required this.asset,
    required this.rank,
    this.onTap,
    super.key,
  });

  final RankedAsset asset;
  final int rank;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    child: Text('$rank'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          asset.symbol,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    PercentFormat.signedPercent(asset.priceChangePct, locale),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: asset.priceChangePct >= 0
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.volumeChangePct}: ${PercentFormat.signedPercent(asset.volumeChangePct, locale)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${l10n.dopamineScoreLabel}: ${asset.dopamineScore.toStringAsFixed(1)}',
                style: theme.textTheme.bodySmall,
              ),
              if (asset.summaryLine != null) ...[
                const SizedBox(height: 8),
                Text(
                  asset.summaryLine!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
