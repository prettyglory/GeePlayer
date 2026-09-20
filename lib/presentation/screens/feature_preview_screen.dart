import 'package:flutter/material.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/presentation/navigation/app_destination.dart';

class FeaturePreviewScreen extends StatelessWidget {
  const FeaturePreviewScreen({required this.destination, super.key});

  final AppDestination destination;

  String get _description => switch (destination) {
    AppDestination.home => 'Your media, your moment.',
    AppDestination.videos =>
      'Your local videos will appear here once media discovery is ready.',
    AppDestination.music =>
      'Your local music will appear here once media discovery is ready.',
    AppDestination.folders =>
      'Browse your accessible media folders here in the next phase.',
    AppDestination.favorites =>
      'Media you mark as a favorite will appear here.',
    AppDestination.settings =>
      'Playback, subtitle, and app preferences are coming in a later phase.',
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: GeeColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: GeeColors.outline),
                  ),
                  child: Icon(
                    destination.icon,
                    size: 38,
                    color: GeeColors.accentLight,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  destination.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  _description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: GeeColors.textMuted, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
