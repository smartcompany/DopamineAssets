import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dopamine_assets/l10n/app_localizations.dart';

import '../../core/analytics/app_analytics.dart';
import '../../core/network/dopamine_api.dart';
import '../../core/translation/news_title_translator.dart';
import '../../data/models/market_summary.dart';
import '../../widgets/async_body.dart';

class MarketSummaryScreen extends StatefulWidget {
  const MarketSummaryScreen({super.key});

  @override
  State<MarketSummaryScreen> createState() => _MarketSummaryScreenState();
}

class _MarketSummaryScreenState extends State<MarketSummaryScreen> {
  late final Future<MarketSummary> _future;
  final Map<String, Future<_LocalizedSummary>> _localizedFutureCache = {};

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
              final localizedFuture = _localizedFuture(summary, lang);
              return FutureBuilder<_LocalizedSummary>(
                future: localizedFuture,
                builder: (context, localizedSnapshot) {
                  final localized = localizedSnapshot.data;
                  final body = localized?.body ?? summary.bodyForLanguageCode(lang);
                  final note =
                      localized?.attribution ??
                      summary.attributionForLanguageCode(lang);
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
          );
        },
      ),
    );
  }

  Future<_LocalizedSummary> _localizedFuture(MarketSummary summary, String lang) {
    final baseLang = lang.toLowerCase();
    final sourceBody = summary.briefingEn?.trim() ?? '';
    final sourceAttribution = summary.attributionEn?.trim() ?? '';
    final key = '$baseLang|$sourceBody|$sourceAttribution';
    return _localizedFutureCache.putIfAbsent(
      key,
      () => _localizeSummary(summary, baseLang),
    );
  }

  Future<_LocalizedSummary> _localizeSummary(
    MarketSummary summary,
    String lang,
  ) async {
    // 서버 원문은 영어로 가정하고, 영어 UI만 원문을 그대로 사용한다.
    if (lang.startsWith('en')) {
      return _LocalizedSummary(
        body: summary.bodyForLanguageCode(lang),
        attribution: summary.attributionForLanguageCode(lang),
      );
    }
    final sourceBody = summary.briefingEn?.trim() ?? '';
    final sourceAttribution = summary.attributionEn?.trim() ?? '';
    if (sourceBody.isEmpty) {
      return _LocalizedSummary(
        body: summary.bodyForLanguageCode(lang),
        attribution: summary.attributionForLanguageCode(lang),
      );
    }
    final translatedBody = await translateTextForAppLocale(sourceBody, lang);
    final translatedAttr = sourceAttribution.isNotEmpty
        ? await translateTextForAppLocale(sourceAttribution, lang)
        : null;
    unawaited(
      AppAnalytics.logMarketSummaryTranslate(
        fromLang: 'en',
        toLang: lang,
        screen: 'market_summary',
      ),
    );
    return _LocalizedSummary(body: translatedBody, attribution: translatedAttr);
  }
}

final class _LocalizedSummary {
  const _LocalizedSummary({required this.body, this.attribution});

  final String body;
  final String? attribution;
}
