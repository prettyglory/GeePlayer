import 'package:flutter/material.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/app/gee_theme.dart';
import 'package:gee_player/presentation/screens/splash_screen.dart';
import 'package:gee_player/presentation/widgets/gee_logo.dart';

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
            : const _LandingScreen(key: ValueKey('landing')),
      ),
    );
  }
}

class _LandingScreen extends StatelessWidget {
  const _LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GeeLogo(size: 92, elevated: true),
              SizedBox(height: 28),
              Text(
                'Gee Player',
                style: TextStyle(
                  color: GeeColors.text,
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your media, your moment.',
                style: TextStyle(color: GeeColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
