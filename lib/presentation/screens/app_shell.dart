import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/app/media_library_providers.dart';
import 'package:gee_player/app/playback_controller.dart';
import 'package:gee_player/app/playback_providers.dart';
import 'package:gee_player/presentation/navigation/app_destination.dart';
import 'package:gee_player/presentation/screens/feature_preview_screen.dart';
import 'package:gee_player/presentation/screens/home_screen.dart';
import 'package:gee_player/presentation/screens/media_library_screen.dart';
import 'package:gee_player/presentation/screens/playback_screen.dart';
import 'package:gee_player/presentation/widgets/gee_logo.dart';
import 'package:gee_player/presentation/widgets/media_artwork.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  AppDestination _selected = AppDestination.home;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(mediaLibraryProvider);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(playbackControllerProvider).saveProgress();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _select(int index) {
    setState(() => _selected = AppDestination.values[index]);
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackControllerProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        final content = AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _selected == AppDestination.home
              ? HomeScreen(
                  key: const ValueKey(AppDestination.home),
                  onNavigate: (destination) => _select(destination.index),
                )
              : switch (_selected) {
                  AppDestination.videos ||
                  AppDestination.music ||
                  AppDestination.folders => MediaLibraryScreen(
                    key: ValueKey(_selected),
                    destination: _selected,
                  ),
                  _ => FeaturePreviewScreen(
                    key: ValueKey(_selected),
                    destination: _selected,
                  ),
                },
        );

        return Scaffold(
          body: wide
              ? Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SafeArea(
                            child: NavigationRail(
                              backgroundColor: GeeColors.surface,
                              selectedIndex: _selected.index,
                              onDestinationSelected: _select,
                              labelType: NavigationRailLabelType.all,
                              minWidth: 92,
                              scrollable: true,
                              leading: const Padding(
                                padding: EdgeInsets.only(top: 18, bottom: 30),
                                child: GeeLogo(size: 48),
                              ),
                              destinations: [
                                for (final destination in AppDestination.values)
                                  NavigationRailDestination(
                                    icon: Icon(destination.icon),
                                    selectedIcon: Icon(
                                      destination.selectedIcon,
                                    ),
                                    label: Text(destination.label),
                                  ),
                              ],
                            ),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(child: content),
                        ],
                      ),
                    ),
                    _MiniPlayer(controller: playback),
                  ],
                )
              : content,
          bottomNavigationBar: wide
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniPlayer(controller: playback),
                    NavigationBar(
                      backgroundColor: GeeColors.surface,
                      selectedIndex: _selected.index,
                      onDestinationSelected: _select,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.onlyShowSelected,
                      destinations: [
                        for (final destination in AppDestination.values)
                          NavigationDestination(
                            icon: Icon(destination.icon, size: 23),
                            selectedIcon: Icon(
                              destination.selectedIcon,
                              size: 23,
                            ),
                            label: destination.label,
                            tooltip: destination.label,
                          ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.controller});

  final PlaybackController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final media = controller.current;
        if (media == null) return const SizedBox.shrink();
        return Material(
          color: GeeColors.surfaceRaised,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PlaybackScreen()),
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    MediaArtwork(media: media, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        media.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: controller.playing ? 'Pause' : 'Play',
                      onPressed: controller.loading
                          ? null
                          : controller.togglePlayPause,
                      icon: Icon(
                        controller.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Stop',
                      onPressed: controller.loading ? null : controller.stop,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
