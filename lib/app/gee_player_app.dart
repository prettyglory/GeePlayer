import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/application_settings_providers.dart';
import 'package:gee_player/app/gee_theme.dart';
import 'package:gee_player/data/settings/application_preferences.dart';
import 'package:gee_player/presentation/screens/app_shell.dart';
import 'package:gee_player/presentation/screens/splash_screen.dart';

class GeePlayerApp extends ConsumerStatefulWidget {
  const GeePlayerApp({super.key});

  @override
  ConsumerState<GeePlayerApp> createState() => _GeePlayerAppState();
}

class _GeePlayerAppState extends ConsumerState<GeePlayerApp> {
  bool _showSplash = true;

  void _finishSplash() {
    if (mounted) setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(applicationSettingsProvider).value ??
        const ApplicationSettings();
    return MaterialApp(
      title: 'Gee Player',
      debugShowCheckedModeBanner: false,
      theme: GeeTheme.dark(
        accentPreference: settings.accent,
        pureBlack: settings.pureBlackTheme,
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _showSplash
            ? SplashScreen(
                key: const ValueKey('splash'),
                onFinished: _finishSplash,
              )
            : const AppShell(key: ValueKey('shell')),
      ),
    );
  }
}
