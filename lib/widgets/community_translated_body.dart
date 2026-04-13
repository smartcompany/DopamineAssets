import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

import '../core/translation/news_title_translator.dart';
import '../theme/dopamine_theme.dart';

typedef _TranslationCacheKey = String;

final Map<_TranslationCacheKey, Future<_TranslationResult>>
    _communityBodyTranslationCache = {};

class _TranslationResult {
  const _TranslationResult({
    required this.translatedText,
    required this.translated,
  });

  final String translatedText;
  final bool translated;
}

bool _sourceMatchesTarget(String sourceCode, String targetCode) {
  final src = sourceCode.toLowerCase();
  final tgt = targetCode.toLowerCase();
  if (src == tgt) return true;
  if (src.startsWith('zh') || tgt.startsWith('zh')) return src == tgt;
  return src.split('-').first == tgt.split('-').first;
}

Future<_TranslationResult> _translateBody(String body, String localeName) async {
  final target = googleTranslateTargetForUiLocale(localeName);
  if (target == null || body.trim().isEmpty) {
    return _TranslationResult(translatedText: body, translated: false);
  }
  final key = '$target|$body';
  final cached = _communityBodyTranslationCache[key];
  if (cached != null) return cached;

  final future = () async {
    try {
      final tr = await GoogleTranslator().translate(body, from: 'auto', to: target);
      if (_sourceMatchesTarget(tr.sourceLanguage.code, target)) {
        return _TranslationResult(translatedText: body, translated: false);
      }
      final out = tr.text.trim();
      if (out.isEmpty || out == body.trim()) {
        return _TranslationResult(translatedText: body, translated: false);
      }
      return _TranslationResult(translatedText: out, translated: true);
    } catch (_) {
      return _TranslationResult(translatedText: body, translated: false);
    }
  }();

  _communityBodyTranslationCache[key] = future;
  return future;
}

class CommunityTranslatedBody extends StatefulWidget {
  const CommunityTranslatedBody({
    super.key,
    required this.body,
    required this.localeName,
    required this.showOriginalLabel,
    required this.showTranslatedLabel,
    this.style,
    this.maxLines,
    this.seeMoreLabel,
    this.onSeeMore,
  });

  final String body;
  final String localeName;
  final TextStyle? style;
  final int? maxLines;
  final String? seeMoreLabel;
  final VoidCallback? onSeeMore;
  final String showOriginalLabel;
  final String showTranslatedLabel;

  @override
  State<CommunityTranslatedBody> createState() => _CommunityTranslatedBodyState();
}

class _CommunityTranslatedBodyState extends State<CommunityTranslatedBody> {
  _TranslationResult? _result;
  bool _showOriginal = false;

  @override
  void initState() {
    super.initState();
    _loadTranslation();
  }

  @override
  void didUpdateWidget(covariant CommunityTranslatedBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.body != widget.body || oldWidget.localeName != widget.localeName) {
      _showOriginal = false;
      _loadTranslation();
    }
  }

  Future<void> _loadTranslation() async {
    final body = widget.body;
    final locale = widget.localeName;
    final r = await _translateBody(body, locale);
    if (!mounted) return;
    if (body != widget.body || locale != widget.localeName) return;
    setState(() => _result = r);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.body.trim();
    if (t.isEmpty) return const SizedBox.shrink();

    final translated = _result?.translated == true;
    final displayText = translated && !_showOriginal
        ? _result!.translatedText
        : widget.body;

    final textStyle =
        widget.style ??
        DefaultTextStyle.of(
          context,
        ).style.copyWith(color: DopamineTheme.textPrimary, height: 1.32);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (translated)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 28),
                  side: BorderSide(
                    color: DopamineTheme.neonGreen.withValues(alpha: 0.55),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () => setState(() => _showOriginal = !_showOriginal),
                child: Text(
                  _showOriginal ? widget.showTranslatedLabel : widget.showOriginalLabel,
                  style: textStyle.copyWith(
                    color: DopamineTheme.neonGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: (textStyle.fontSize ?? 14) * 0.84,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        if (widget.maxLines == null)
          Text(displayText, style: textStyle)
        else
          _BodySnippet(
            body: displayText,
            style: textStyle,
            maxLines: widget.maxLines!,
            seeMoreLabel: widget.seeMoreLabel ?? '',
            onSeeMore: widget.onSeeMore,
          ),
      ],
    );
  }
}

class _BodySnippet extends StatelessWidget {
  const _BodySnippet({
    required this.body,
    required this.style,
    required this.maxLines,
    required this.seeMoreLabel,
    this.onSeeMore,
  });

  final String body;
  final TextStyle style;
  final int maxLines;
  final String seeMoreLabel;
  final VoidCallback? onSeeMore;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: body, style: style),
          textDirection: Directionality.of(context),
          maxLines: maxLines,
        )..layout(maxWidth: constraints.maxWidth);

        final clipped = painter.didExceedMaxLines;
        final showLink = clipped && onSeeMore != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
            if (showLink) ...[
              const SizedBox(height: 6),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSeeMore,
                child: Text(
                  seeMoreLabel,
                  style: style.copyWith(
                    color: DopamineTheme.neonGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: (style.fontSize ?? 14) * 0.92,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
