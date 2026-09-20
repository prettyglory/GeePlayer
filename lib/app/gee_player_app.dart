import 'package:flutter/material.dart';
import 'package:gee_player/app/gee_theme.dart';
import 'package:gee_player/presentation/screens/app_shell.dart';
import 'package:gee_player/presentation/screens/splash_screen.dart';

class GeePlayerApp extends StatefulWidget {
  const GeePlayerApp({super.key});

  @override
  State<GeePlayerApp> createState() => _GeePlayerAppState();
}

class _GeePlayerAppState extends State<GeePlayerApp> {
  bool _showSplash = true;

  void _finishSplash() {
    if (mounted) setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gee Player',
      debugShowCheckedModeBanner: false,
      theme: GeeTheme.dark,
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
