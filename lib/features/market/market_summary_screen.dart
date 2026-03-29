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
              final lang = Localizations.localeOf(context).languageCode;
              final body = summary.bodyForLanguageCode(lang);
              final note = summary.attributionForLanguageCode(lang);
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    l10n.marketSummaryTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    body.isNotEmpty ? body : l10n.notAvailable,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
                  ),
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      note,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
