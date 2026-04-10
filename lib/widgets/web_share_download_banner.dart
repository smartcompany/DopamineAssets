import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/dopamine_theme.dart';

/// 공유 링크의 `?from=share` 또는 (구) `from=community_share` 진입 시 표시.
abstract final class WebShareDownloadBannerLogic {
  static bool get shouldShow {
    if (!kIsWeb) return false;
    final from = Uri.base.queryParameters['from']?.toLowerCase();
    return from == 'share' || from == 'community_share';
  }
}

class WebShareDownloadBanner extends StatelessWidget {
  const WebShareDownloadBanner({super.key, required this.onContinueOnWeb});

  /// "웹으로 계속 보기" 후 배너를 닫고 UI를 갱신하기 위해 호출.
  final VoidCallback onContinueOnWeb;

  /// 설치됨 → 앱 열기, 아니면 스토어 등으로 안내 (서버 applink).
  static final Uri _applinkUri =
      Uri.parse('https://dopamine-assets-server.vercel.app/applink');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.phone_iphone_rounded,
              size: 22,
              color: DopamineTheme.neonGreen.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '앱에서 더 빠르게',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: DopamineTheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '앱이 있으면 바로 열고, 없으면 설치 안내로 연결돼요',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: DopamineTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => launchUrl(_applinkUri),
          style: FilledButton.styleFrom(
            backgroundColor: DopamineTheme.neonGreen,
            foregroundColor: const Color(0xFF0A0A0A),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            '앱에서 열기',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: onContinueOnWeb,
            style: TextButton.styleFrom(
              foregroundColor: DopamineTheme.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            child: Text(
              '웹으로 계속 보기',
              style: theme.textTheme.labelLarge?.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: DopamineTheme.textSecondary.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
