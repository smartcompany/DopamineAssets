import 'package:flutter/material.dart';

/// 캡처 기준: 딥 퍼플 그라데이션 + 네온 그린 액센트 + 글래스 UI
abstract final class DopamineTheme {
  static const Color purpleTop = Color(0xFF6B3FA0);
  static const Color purpleBottom = Color(0xFF0D0618);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color accentOrange = Color(0xFFFF6B00);
  static const Color accentRed = Color(0xFFFF5252);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8C8);
  static const Color scaffoldBase = Color(0xFF13081F);

  static ThemeData get dopamine {
    final base = ColorScheme.fromSeed(
      seedColor: purpleTop,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: base.copyWith(
        surface: scaffoldBase,
        surfaceContainerHighest: const Color(0xFF2A1F3D),
        primary: neonGreen,
        onSurface: textPrimary,
        onPrimary: const Color(0xFF0A0A0A),
      ),
      scaffoldBackgroundColor: scaffoldBase,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textSecondary,
        indicatorColor: neonGreen,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: neonGreen.withValues(alpha: 0.22),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
            color: selected ? textPrimary : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? neonGreen : textSecondary,
            size: 24,
          );
        }),
      ),
    );
  }
}
