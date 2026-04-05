import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:share_lib/share_lib.dart';

import '../config/api_config.dart';

/// 앱 프로세스가 살아 있는 동안만 유지. 재시작 시 `watchedAdThisSession` 은 다시 false.
abstract final class InterestSurgeExpandAdGate {
  InterestSurgeExpandAdGate._();

  static bool watchedAdThisSession = false;
  static bool _settingsLoaded = false;

  static Future<void> _ensureAdSettings() async {
    if (_settingsLoaded) return;
    AdService.shared.setBaseUrl(ApiConfig.baseUrl);
    await AdService.shared.loadSettings();
    _settingsLoaded = true;
  }

  /// 세션에서 아직 광고를 안 봤으면 전면 광고를 띄우고, 닫힘/실패 후 진행.
  /// ([AssetNewsSection] 과 동일하게 `showAd` Future 는 즉시 끝나므로 completer 로 닫힘을 기다립니다.)
  static Future<void> runAdBeforeFirstExpandIfNeeded() async {
    if (watchedAdThisSession) return;
    await _ensureAdSettings();
    final adDone = Completer<void>();
    unawaited(
      AdService.shared.showAd(
        onAdDismissed: () {
          if (!adDone.isCompleted) adDone.complete();
        },
        onAdFailedToShow: () {
          if (kDebugMode) {
            debugPrint('[InterestSurge] ad failed to show, unlock expand');
          }
          if (!adDone.isCompleted) adDone.complete();
        },
      ),
    );
    await adDone.future;
    watchedAdThisSession = true;
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}
