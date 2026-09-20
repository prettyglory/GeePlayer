import 'package:flutter/material.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/presentation/navigation/app_destination.dart';
import 'package:gee_player/presentation/widgets/gee_logo.dart';
import 'package:gee_player/presentation/widgets/home_section_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onNavigate, super.key});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final padding = wide ? 32.0 : 20.0;

          return SingleChildScrollView(
            key: const PageStorageKey('home-scroll'),
            padding: EdgeInsets.fromLTRB(padding, 24, padding, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _HomeHeader(),
                    const SizedBox(height: 28),
                    const _HomeHero(),
                    const SizedBox(height: 28),
                    Text(
                      'Your library',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    _QuickLinks(onNavigate: onNavigate),
                    const SizedBox(height: 28),
                    Text(
                      'Pick up where you left off',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    _SectionGrid(
                      wide: wide,
                      children: const [
                        HomeSectionCard(
                          title: 'Continue watching',
                          message:
                              'Videos you start will be ready to resume here.',
                          icon: Icons.play_circle_outline_rounded,
                        ),
                        HomeSectionCard(
                          title: 'Recently played',
                          message: 'Your listening and viewing history will appear here.',
                          icon: Icons.history_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Fresh in your collection',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    _SectionGrid(
                      wide: wide,
                      children: [
                        HomeSectionCard(
                          title: 'Recently added videos',
                          message:
                              'Videos found on your device will appear here.',
                          icon: Icons.movie_outlined,
                          onOpen: () => onNavigate(AppDestination.videos),
                        ),
                        HomeSectionCard(
                          title: 'Recently added music',
                          message:
                              'Songs found on your device will appear here.',
                          icon: Icons.music_note_outlined,
                          onOpen: () => onNavigate(AppDestination.music),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    HomeSectionCard(
                      title: 'Media folders',
                      message:
                          'Your accessible media folders will appear here.',
                      icon: Icons.folder_outlined,
                      onOpen: () => onNavigate(AppDestination.folders),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const GeeLogo(size: 42),
        const SizedBox(width: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gee Player',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
            ),
            const Text(
              'Your media, your moment.',
              style: TextStyle(color: GeeColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 206),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF244C94), Color(0xFF172F62), GeeColors.surface],
        ),
        border: Border.all(color: const Color(0xFF3C68AA)),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -16,
            bottom: -52,
            child: Icon(
              Icons.play_circle_fill_rounded,
              size: 224,
              color: Color(0x224A90FF),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 510),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WELCOME TO GEE PLAYER',
                    style: TextStyle(
                      color: GeeColors.accentLight,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'All your media. One place.',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800, height: 1.1),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Explore your videos and music with a space designed around your collection.',
                    style: TextStyle(color: GeeColors.textMuted, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks({required this.onNavigate});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 540;
        final destinations = [
          AppDestination.videos,
          AppDestination.music,
          AppDestination.folders,
        ];

        return Row(
          children: [
            for (var index = 0; index < destinations.length; index++) ...[
              if (index > 0) const SizedBox(width: 10),
              Expanded(
                child: _QuickLink(
                  destination: destinations[index],
                  compact: compact,
                  onTap: () => onNavigate(destinations[index]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.destination,
    required this.compact,
    required this.onTap,
  });

  final AppDestination destination;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GeeColors.surfaceRaised,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: ValueKey('quick-${destination.label.toLowerCase()}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 18,
            vertical: compact ? 16 : 20,
          ),
          child: compact
              ? Column(
                  children: [
                    Icon(destination.icon, color: GeeColors.accentLight),
                    const SizedBox(height: 8),
                    Text(
                      destination.label,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(destination.icon, color: GeeColors.accentLight),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        destination.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SectionGrid extends StatelessWidget {
  const _SectionGrid({required this.wide, required this.children});

  final bool wide;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: 14),
            children[index],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(width: 14),
          Expanded(child: children[index]),
        ],
      ],
    );
  }
}
