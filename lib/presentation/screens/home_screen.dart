import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/app/media_library_providers.dart';
import 'package:gee_player/app/media_collections_providers.dart';
import 'package:gee_player/domain/media/library_snapshot.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/domain/media/media_library_query.dart';
import 'package:gee_player/presentation/navigation/app_destination.dart';
import 'package:gee_player/presentation/widgets/gee_logo.dart';
import 'package:gee_player/presentation/widgets/home_section_card.dart';
import 'package:gee_player/presentation/widgets/media_state_panel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({required this.onNavigate, super.key});

  final ValueChanged<AppDestination> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(mediaLibraryProvider);
    final collections = ref.watch(mediaCollectionsProvider).value;
    final snapshot = library.value;
    final videos = snapshot == null
        ? <LocalMedia>[]
        : MediaLibraryQuery.searchAndSort(
            snapshot.videos,
            query: '',
            sort: MediaSort.newest,
          );
    final music = snapshot == null
        ? <LocalMedia>[]
        : MediaLibraryQuery.searchAndSort(
            snapshot.music,
            query: '',
            sort: MediaSort.newest,
          );
    final folders = snapshot?.folders ?? [];
    final status = library.isLoading
        ? MediaViewStatus.loading
        : library.hasError
        ? MediaViewStatus.error
        : MediaViewStatus.empty;
    final videoDenied = snapshot?.access.videos == MediaAccessLevel.denied;
    final audioDenied = snapshot?.access.audio == MediaAccessLevel.denied;

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
                    _HomeHeader(
                      onRefresh: () =>
                          ref.read(mediaLibraryProvider.notifier).refresh(),
                    ),
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
                      children: [
                        HomeSectionCard(
                          title: 'Continue watching',
                          message:
                              'Videos you start will be ready to resume here.',
                          icon: Icons.play_circle_outline_rounded,
                          previewTitles:
                              collections?.continueWatching
                                  .take(3)
                                  .map((item) => item.media.title)
                                  .toList() ??
                              const [],
                        ),
                        HomeSectionCard(
                          title: 'Recently played',
                          message: 'Your listening and viewing history will appear here.',
                          icon: Icons.history_rounded,
                          previewTitles:
                              collections?.recent
                                  .take(3)
                                  .map((item) => item.title)
                                  .toList() ??
                              const [],
                          onOpen: () => onNavigate(AppDestination.favorites),
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
                          message: library.hasError
                              ? 'Could not load your videos.'
                              : videoDenied
                              ? 'Allow video access to discover your videos.'
                              : 'No videos found yet.',
                          icon: Icons.movie_outlined,
                          onOpen: () => onNavigate(AppDestination.videos),
                          previewTitles: videos
                              .take(3)
                              .map((item) => item.title)
                              .toList(),
                          status: status,
                          actionLabel: videoDenied
                              ? 'Allow access'
                              : 'Try again',
                          onAction: videoDenied
                              ? () => ref
                                    .read(mediaLibraryProvider.notifier)
                                    .requestAccess(kind: MediaKind.video)
                              : library.hasError
                              ? () => ref
                                    .read(mediaLibraryProvider.notifier)
                                    .refresh()
                              : null,
                        ),
                        HomeSectionCard(
                          title: 'Recently added music',
                          message: library.hasError
                              ? 'Could not load your music.'
                              : audioDenied
                              ? 'Allow audio access to discover your music.'
                              : 'No music found yet.',
                          icon: Icons.music_note_outlined,
                          onOpen: () => onNavigate(AppDestination.music),
                          previewTitles: music
                              .take(3)
                              .map((item) => item.title)
                              .toList(),
                          status: status,
                          actionLabel: audioDenied
                              ? 'Allow access'
                              : 'Try again',
                          onAction: audioDenied
                              ? () => ref
                                    .read(mediaLibraryProvider.notifier)
                                    .requestAccess(kind: MediaKind.audio)
                              : library.hasError
                              ? () => ref
                                    .read(mediaLibraryProvider.notifier)
                                    .refresh()
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    HomeSectionCard(
                      title: 'Media folders',
                      message: library.hasError
                          ? 'Could not load your folders.'
                          : videoDenied && audioDenied
                          ? 'Allow media access to discover folders.'
                          : 'No media folders found yet.',
                      icon: Icons.folder_outlined,
                      onOpen: () => onNavigate(AppDestination.folders),
                      previewTitles: folders
                          .take(3)
                          .map((folder) => folder.name)
                          .toList(),
                      status: status,
                      actionLabel: videoDenied && audioDenied
                          ? 'Allow access'
                          : 'Try again',
                      onAction: videoDenied && audioDenied
                          ? () => ref
                                .read(mediaLibraryProvider.notifier)
                                .requestAccess()
                          : library.hasError
                          ? () => ref
                                .read(mediaLibraryProvider.notifier)
                                .refresh()
                          : null,
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
  const _HomeHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const GeeLogo(size: 42),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gee Player',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const Text(
                'Your media, your moment.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: GeeColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh library',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 206),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(colors.primary, colors.surface, 0.2)!,
            Color.lerp(colors.primary, colors.surface, 0.62)!,
            colors.surface,
          ],
        ),
        border: Border.all(color: colors.primary.withValues(alpha: 0.55)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -52,
            child: Icon(
              Icons.play_circle_fill_rounded,
              size: 224,
              color: colors.primary.withValues(alpha: 0.14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 510),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WELCOME TO GEE PLAYER',
                    style: TextStyle(
                      color: colors.primary,
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
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
                    Icon(
                      destination.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
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
                    Icon(
                      destination.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
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
