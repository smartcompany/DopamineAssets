import 'package:flutter/material.dart';

import '../theme/dopamine_theme.dart';

/// 반투명 오버레이 + 인디케이터. [action] 완료·예외 후 자동으로 닫힙니다.
Future<T> runWithFullscreenLoading<T>(
  BuildContext context,
  Future<T> action,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (ctx) => PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.45),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DopamineTheme.neonGreen,
            ),
          ),
        ),
      ),
    ),
  );
  try {
    return await action;
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
