import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/presentation/widgets/gee_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.onFinished, super.key});

  static const displayDuration = Duration(milliseconds: 1250);

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _reveal;
  Timer? _finishTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _reveal = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
    _finishTimer = Timer(SplashScreen.displayDuration, widget.onFinished);
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 1.15,
            colors: [Color(0xFF19345E), GeeColors.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _reveal,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(_reveal),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GeeLogo(size: 112, elevated: true),
                      SizedBox(height: 32),
                      Text(
                        'Gee Player',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GeeColors.text,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.1,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Your media, your moment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GeeColors.textMuted,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
