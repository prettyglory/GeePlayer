import 'package:flutter/material.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/data/settings/application_preferences.dart';

abstract final class GeeTheme {
  static ThemeData dark({
    AccentPreference accentPreference = AccentPreference.electricBlue,
    bool pureBlack = false,
  }) {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final accent = switch (accentPreference) {
      AccentPreference.electricBlue => GeeColors.accent,
      AccentPreference.cyan => const Color(0xFF00BCD4),
      AccentPreference.violet => const Color(0xFF8B7CFF),
    };
    final background = pureBlack ? Colors.black : GeeColors.background;
    final surface = pureBlack ? const Color(0xFF101010) : GeeColors.surface;
    final raisedSurface = pureBlack
        ? const Color(0xFF181818)
        : GeeColors.surfaceRaised;

    return base.copyWith(
      colorScheme:
          ColorScheme.dark(
            primary: accent,
            onPrimary: GeeColors.text,
            secondary: accent,
            onSecondary: background,
            surface: surface,
            onSurface: GeeColors.text,
            onSurfaceVariant: GeeColors.textMuted,
            outline: GeeColors.outline,
          ).copyWith(
            surfaceContainer: surface,
            surfaceContainerHigh: raisedSurface,
          ),
      scaffoldBackgroundColor: background,
      dividerColor: GeeColors.outline,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
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
