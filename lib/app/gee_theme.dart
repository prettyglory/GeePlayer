import 'package:flutter/material.dart';
import 'package:gee_player/app/gee_colors.dart';

abstract final class GeeTheme {
  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: GeeColors.accent,
        onPrimary: GeeColors.text,
        secondary: GeeColors.accentLight,
        onSecondary: GeeColors.background,
        surface: GeeColors.surface,
        onSurface: GeeColors.text,
        outline: GeeColors.outline,
      ),
      scaffoldBackgroundColor: GeeColors.background,
      dividerColor: GeeColors.outline,
      appBarTheme: const AppBarTheme(
        backgroundColor: GeeColors.background,
        foregroundColor: GeeColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: base.textTheme
          .apply(bodyColor: GeeColors.text, displayColor: GeeColors.text)
          .copyWith(
            displaySmall: base.textTheme.displaySmall?.copyWith(
              color: GeeColors.text,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.3,
            ),
            headlineMedium: base.textTheme.headlineMedium?.copyWith(
              color: GeeColors.text,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.7,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(
              color: GeeColors.text,
              fontWeight: FontWeight.w700,
            ),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(
              color: GeeColors.textMuted,
            ),
          ),
    );
  }
}
