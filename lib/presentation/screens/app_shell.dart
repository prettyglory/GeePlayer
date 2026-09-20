import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/app/media_library_providers.dart';
import 'package:gee_player/presentation/navigation/app_destination.dart';
import 'package:gee_player/presentation/screens/feature_preview_screen.dart';
import 'package:gee_player/presentation/screens/home_screen.dart';
import 'package:gee_player/presentation/screens/media_library_screen.dart';
import 'package:gee_player/presentation/widgets/gee_logo.dart';

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
              ? Row(
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
                              selectedIcon: Icon(destination.selectedIcon),
                              label: Text(destination.label),
                            ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  backgroundColor: GeeColors.surface,
                  selectedIndex: _selected.index,
                  onDestinationSelected: _select,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                  destinations: [
                    for (final destination in AppDestination.values)
                      NavigationDestination(
                        icon: Icon(destination.icon, size: 23),
                        selectedIcon: Icon(destination.selectedIcon, size: 23),
                        label: destination.label,
                        tooltip: destination.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
