import 'package:flutter/material.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/app/gee_theme.dart';
import 'package:gee_player/presentation/widgets/gee_logo.dart';

class GeePlayerApp extends StatelessWidget {
  const GeePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gee Player',
      debugShowCheckedModeBanner: false,
      theme: GeeTheme.dark,
      home: const Scaffold(
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
      ),
    );
  }
}
