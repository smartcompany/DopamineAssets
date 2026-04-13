import 'package:flutter/material.dart';
import 'package:share_lib/share_lib.dart';

import '../l10n/app_localizations.dart';
import '../theme/dopamine_theme.dart';

/// 앱 공용 공유 옵션 시트
abstract final class CommonShareUI {
  static Rect? _shareOriginFromContext(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static Future<void> showShareOptionsDialog({
    required BuildContext context,
    required String shareText,
    Uri? linkUrl,
  }) async {
    final shareOrigin = _shareOriginFromContext(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171327),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        final textTheme = Theme.of(ctx).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.yellow,
                  ),
                  title: Text(
                    l10n.shareSheetKakaoTalk,
                    style: textTheme.titleMedium,
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                          final kakaoText = _mergeTextAndUrl(shareText, linkUrl);
                    await _shareToKakaoCompat(
                            kakaoText,
                      linkUrl: linkUrl,
                      onKakaoNotInstalled: () async {
                        await _shareTextCompat(
                                kakaoText,
                          sharePositionOrigin: shareOrigin,
                        );
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.share_outlined,
                    color: DopamineTheme.neonGreen,
                  ),
                  title: Text(
                    l10n.shareSheetSystemShare,
                    style: textTheme.titleMedium,
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _shareTextCompat(
                      _mergeTextAndUrl(shareText, linkUrl),
                      sharePositionOrigin: shareOrigin,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_rounded, color: Colors.white70),
                  title: Text(
                    l10n.shareSheetCopyLink,
                    style: textTheme.titleMedium,
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ShareService.copyToClipboard(
                      _mergeTextAndUrl(shareText, linkUrl),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.shareSheetCopied)),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// share_lib 버전 호환:
  /// - 최신: sharePositionOrigin 지원
  /// - 구버전: 미지원 (기본 시그니처로 폴백)
  static Future<void> _shareTextCompat(
    String shareText, {
    Rect? sharePositionOrigin,
  }) async {
    try {
      await Function.apply(
        ShareService.shareText,
        [shareText],
        {
          if (sharePositionOrigin != null) #sharePositionOrigin: sharePositionOrigin,
        },
      );
    } catch (_) {
      await ShareService.shareText(shareText);
    }
  }

  static Future<void> _shareToKakaoCompat(
    String shareText, {
    Uri? linkUrl,
    VoidCallback? onSuccess,
    Function(String error)? onError,
    VoidCallback? onKakaoNotInstalled,
  }) async {
    try {
      await Function.apply(
        ShareService.shareToKakao,
        [shareText],
        {
          if (linkUrl != null) #linkUrl: linkUrl,
          if (onSuccess != null) #onSuccess: onSuccess,
          if (onError != null) #onError: onError,
          if (onKakaoNotInstalled != null)
            #onKakaoNotInstalled: onKakaoNotInstalled,
        },
      );
    } catch (_) {
      await ShareService.shareToKakao(
        shareText,
        onSuccess: onSuccess,
        onError: onError,
        onKakaoNotInstalled: onKakaoNotInstalled,
      );
    }
  }

  static String _mergeTextAndUrl(String shareText, Uri? linkUrl) {
    if (linkUrl == null) return shareText;
    return '$shareText\n${linkUrl.toString()}';
  }
}

