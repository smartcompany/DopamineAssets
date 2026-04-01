import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// 시총 문자열을 숫자(·통화) 구간과 단위 구간으로 나눔 — 단위만 다른 색으로 쓸 때 사용.
final class MarketCapSplit {
  const MarketCapSplit.split({required this.main, required this.suffix})
      : single = null;

  const MarketCapSplit.single(this.single) : main = null, suffix = null;

  final String? main;
  final String? suffix;
  final String? single;

  bool get isSplit => main != null && suffix != null;

  String get asPlain => isSplit ? '$main$suffix' : (single ?? '');
}

MarketCapSplit _resolveMarketCapSplit(
  AppLocalizations l10n, {
  required String? marketCapFromApi,
  required double? marketCapRaw,
  required String? currencyCode,
}) {
  final cur = currencyCode?.toUpperCase();
  final koUi = l10n.localeName.toLowerCase().startsWith('ko');
  if (koUi &&
      cur == 'KRW' &&
      marketCapRaw != null &&
      marketCapRaw > 0 &&
      marketCapRaw.isFinite) {
    if (marketCapRaw < 1e6) {
      final nf = NumberFormat.decimalPattern('ko');
      final numStr = nf.format(marketCapRaw.round());
      return MarketCapSplit.split(main: '₩$numStr', suffix: '원');
    }
    final millions = marketCapRaw / 1e6;
    final rounded = millions.round();
    final nfMillions = NumberFormat('#,##0', 'ko');
    final numStr = nfMillions.format(rounded);
    return MarketCapSplit.split(main: '₩$numStr', suffix: '백만');
  }

  final s = marketCapFromApi?.trim() ?? '';
  if (s.isEmpty) {
    return MarketCapSplit.single(l10n.assetDetailNotAvailable);
  }

  final compact = RegExp(r'^(\D*)([\d,\.]+)\s*([A-Za-z]+)$');
  final m = compact.firstMatch(s);
  if (m != null) {
    final prefix = m.group(1) ?? '';
    final digits = m.group(2) ?? '';
    final unit = m.group(3) ?? '';
    return MarketCapSplit.split(main: '$prefix$digits', suffix: unit);
  }

  return MarketCapSplit.single(s);
}

/// 한국어 UI + KRW 시 [marketCapRaw](원)으로 업비트·포털과 비슷한 **백만** 단위 표기.
String displayMarketCapForDetail(
  AppLocalizations l10n, {
  required String? marketCapFromApi,
  required double? marketCapRaw,
  required String? currencyCode,
}) {
  return _resolveMarketCapSplit(
    l10n,
    marketCapFromApi: marketCapFromApi,
    marketCapRaw: marketCapRaw,
    currencyCode: currencyCode,
  ).asPlain;
}

/// 개요 시총 행용 — 숫자·통화는 [mainStyle], 단위(백만·원·B·M 등)는 [unitStyle].
List<InlineSpan> marketCapValueSpans(
  AppLocalizations l10n, {
  required TextStyle mainStyle,
  required TextStyle unitStyle,
  required String? marketCapFromApi,
  required double? marketCapRaw,
  required String? currencyCode,
}) {
  final split = _resolveMarketCapSplit(
    l10n,
    marketCapFromApi: marketCapFromApi,
    marketCapRaw: marketCapRaw,
    currencyCode: currencyCode,
  );
  if (split.isSplit) {
    return [
      TextSpan(text: split.main!, style: mainStyle),
      TextSpan(text: split.suffix!, style: unitStyle),
    ];
  }
  return [TextSpan(text: split.single!, style: mainStyle)];
}
