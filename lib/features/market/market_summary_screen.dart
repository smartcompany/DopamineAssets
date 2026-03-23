import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';

import '../../core/network/dopamine_api.dart';
import '../../data/models/market_summary.dart';
import '../../widgets/async_body.dart';

class MarketSummaryScreen extends StatefulWidget {
  const MarketSummaryScreen({super.key});

  @override
  State<MarketSummaryScreen> createState() => _MarketSummaryScreenState();
}

class _MarketSummaryScreenState extends State<MarketSummaryScreen> {
  late final Future<MarketSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = DopamineApi.fetchMarketSummary();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMarket)),
      body: FutureBuilder<MarketSummary>(
        future: _future,
        builder: (context, snapshot) {
          return buildAsyncBody<MarketSummary>(
            context: context,
            snapshot: snapshot,
            onData: (context, summary) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    l10n.marketSummaryTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _SummaryRow(
                    label: l10n.kimchiPremiumLabel,
                    value: summary.kimchiPremiumPct == null
                        ? l10n.notAvailable
                        : '${summary.kimchiPremiumPct!.toStringAsFixed(2)}%',
                  ),
                  _SummaryRow(
                    label: l10n.exchangeRateLabel,
                    value: summary.usdKrw == null
                        ? l10n.notAvailable
                        : summary.usdKrw!.toStringAsFixed(2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.marketStatusLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary.marketStatus ?? l10n.notAvailable,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
