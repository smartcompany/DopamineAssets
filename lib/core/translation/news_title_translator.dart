import 'package:translator/translator.dart';

import '../../data/models/asset_news.dart';

/// Google이 감지한 원문 언어가 UI 목표와 같으면(이미 그 언어) 원문 유지.
bool _sourceMatchesUiTarget(String detectedSourceCode, String targetCode) {
  final src = detectedSourceCode.toLowerCase();
  final tgt = targetCode.toLowerCase();
  if (src == tgt) return true;
  if (src.startsWith('zh') || tgt.startsWith('zh')) {
    return src == tgt;
  }
  final srcBase = src.split('-').first;
  final tgtBase = tgt.split('-').first;
  return srcBase == tgtBase;
}

/// UI 로케일 → Google Translate `to` 코드. 지원하지 않으면 `null`(번역 생략).
String? googleTranslateTargetForUiLocale(String appLocaleName) {
  final raw = appLocaleName.trim().toLowerCase();
  if (raw.isEmpty) return null;
  final primary = raw.split(RegExp('[-_]')).first;
  switch (primary) {
    case 'en':
      return 'en';
    case 'ko':
      return 'ko';
    case 'zh':
    case 'zh-cn':
    case 'zhcn':
      return 'zh-cn';
    case 'zh-tw':
    case 'zhtw':
      return 'zh-tw';
    default:
      return primary.length >= 2 && primary != 'auto' ? primary : null;
  }
}

Future<String> _translateLineIfNeeded(
  String text,
  GoogleTranslator translator,
  String targetCode,
) async {
  final t = text.trim();
  if (t.isEmpty) return text;
  try {
    final tr = await translator.translate(t, from: 'auto', to: targetCode);
    if (_sourceMatchesUiTarget(tr.sourceLanguage.code, targetCode)) {
      return t;
    }
    final out = tr.text.trim();
    return out.isNotEmpty ? out : t;
  } catch (_) {
    return t;
  }
}

/// 뉴스 피드 제목을 UI 언어로 맞춤. 원문이 이미 그 언어면 그대로 둔다.
Future<AssetNewsFeed> localizeNewsTitles(
  AssetNewsFeed feed,
  String appLocaleName,
) async {
  if (feed.loadFailed || feed.items.isEmpty) {
    return feed;
  }

  final target = googleTranslateTargetForUiLocale(appLocaleName);
  if (target == null) {
    return feed;
  }

  final translator = GoogleTranslator();
  final items = await Future.wait(
    feed.items.map((item) async {
      final title = item.title.trim();
      if (title.isEmpty) return item;
      final out = await _translateLineIfNeeded(title, translator, target);
      return AssetNewsItem(
        title: out,
        url: item.url,
        publishedAt: item.publishedAt,
        source: item.source,
      );
    }),
  );

  return AssetNewsFeed(items: items);
}

/// 긴 본문(예: 기업 소개)도 UI 로케일에 맞게 번역할 때 사용.
Future<String> translateTextForAppLocale(
  String text,
  String appLocaleName,
) async {
  final t = text.trim();
  if (t.isEmpty) return text;
  final target = googleTranslateTargetForUiLocale(appLocaleName);
  if (target == null) return text;
  final translator = GoogleTranslator();
  return _translateLineIfNeeded(t, translator, target);
}
