import 'package:translator/translator.dart';

import '../../data/models/asset_news.dart';

/// 서버는 영문 제목만 준다고 가정하고, 기기에서 제목만 번역한다.
///
/// [appLocaleName] 은 [AppLocalizations.localeName] 과 같게 넘기면
/// `intl` / ARB UI 언어와 번역 대상이 맞는다.
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
      try {
        final t = await translator.translate(
          title,
          from: 'auto',
          to: target,
        );
        final out = t.text.trim();
        return AssetNewsItem(
          title: out.isNotEmpty ? out : item.title,
          url: item.url,
          publishedAt: item.publishedAt,
          source: item.source,
        );
      } catch (_) {
        return item;
      }
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
  try {
    final translator = GoogleTranslator();
    final out = await translator.translate(t, from: 'auto', to: target);
    final s = out.text.trim();
    return s.isNotEmpty ? s : text;
  } catch (_) {
    return text;
  }
}

/// `null` 이면 번역 생략(영어 UI 등).
String? googleTranslateTargetForUiLocale(String appLocaleName) {
  final raw = appLocaleName.trim().toLowerCase();
  if (raw.isEmpty) return null;
  final primary = raw.split(RegExp('[-_]')).first;
  if (primary == 'en') return null;

  switch (primary) {
    case 'zh':
    case 'zh-cn':
    case 'zhcn':
      return 'zh-cn';
    case 'zh-tw':
    case 'zhtw':
      return 'zh-tw';
    default:
      return primary;
  }
}
