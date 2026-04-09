import 'package:flutter/material.dart';
import 'package:share_lib/share_lib.dart';

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
  }) async {
    final shareOrigin = _shareOriginFromContext(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171327),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
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
                  title: Text('카카오톡 공유', style: textTheme.titleMedium),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ShareService.shareToKakao(
                      shareText,
                      onKakaoNotInstalled: () async {
                        await ShareService.shareText(
                          shareText,
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
                  title: Text('기본 공유', style: textTheme.titleMedium),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ShareService.shareText(
                      shareText,
                      sharePositionOrigin: shareOrigin,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_rounded, color: Colors.white70),
                  title: Text('링크 복사', style: textTheme.titleMedium),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ShareService.copyToClipboard(shareText);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('복사되었습니다')),
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
}

