import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/app/media_library_providers.dart';
import 'package:gee_player/domain/media/library_snapshot.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/domain/media/media_library_query.dart';
import 'package:gee_player/presentation/navigation/app_destination.dart';
import 'package:gee_player/presentation/widgets/media_list_tile.dart';
import 'package:gee_player/presentation/widgets/media_state_panel.dart';

class MediaLibraryScreen extends ConsumerStatefulWidget {
  const MediaLibraryScreen({required this.destination, super.key});

  final AppDestination destination;

  @override
  ConsumerState<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends ConsumerState<MediaLibraryScreen> {
  final _searchController = TextEditingController();
  MediaSort _sort = MediaSort.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  MediaKind? get _kind => switch (widget.destination) {
    AppDestination.videos => MediaKind.video,
    AppDestination.music => MediaKind.audio,
    _ => null,
  };

  Future<void> _import() async {
    final count = await ref.read(mediaLibraryProvider.notifier).importFiles();
    if (!mounted || count == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 0
              ? 'No supported video or audio files were selected.'
              : 'Imported $count media ${count == 1 ? 'file' : 'files'}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(mediaLibraryProvider);
    final canImport = ref
        .watch(localMediaRepositoryProvider)
        .supportsFileImport;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.destination.label,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh library',
                  onPressed: () =>
                      ref.read(mediaLibraryProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                ),
                if (canImport)
                  IconButton(
                    tooltip: 'Import media files',
                    onPressed: _import,
                    icon: const Icon(Icons.add_rounded),
                  ),
              ],
            ),
          ),
          if (library is AsyncData<LibrarySnapshot>)
            _LibraryControls(
              searchController: _searchController,
              sort: _sort,
              showSort: widget.destination != AppDestination.folders,
              onSearchChanged: (_) => setState(() {}),
              onSortChanged: (sort) => setState(() => _sort = sort),
            ),
          Expanded(
            child: switch (library) {
              AsyncData(:final value) => _buildLibrary(value, canImport),
              AsyncError() => MediaStatePanel(
                status: MediaViewStatus.error,
                message:
                    'Could not load your media. Check access and try again.',
                onRetry: () =>
                    ref.read(mediaLibraryProvider.notifier).refresh(),
              ),
              _ => const MediaStatePanel(
                status: MediaViewStatus.loading,
                message: 'Finding your media…',
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLibrary(LibrarySnapshot snapshot, bool canImport) {
    final access = snapshot.access;
    if (access.videos == MediaAccessLevel.unsupported &&
        access.audio == MediaAccessLevel.unsupported) {
      return const MediaStatePanel(
        status: MediaViewStatus.empty,
        icon: Icons.phone_android_rounded,
        message: 'Local media discovery is available on Android and iOS.',
      );
    }

    final videoDenied = access.videos == MediaAccessLevel.denied;
    final audioDenied = access.audio == MediaAccessLevel.denied;
    final blocked = switch (widget.destination) {
      AppDestination.videos => videoDenied,
      AppDestination.music => audioDenied,
      AppDestination.folders => videoDenied && audioDenied,
      _ => false,
    };
    if (blocked) {
      return MediaStatePanel(
        status: MediaViewStatus.empty,
        icon: Icons.lock_outline_rounded,
        message: switch (widget.destination) {
          AppDestination.videos =>
            'Allow video access to discover movies on this device.',
          AppDestination.music =>
            'Allow audio access to discover music on this device.',
          _ => 'Allow media access to discover folders on this device.',
        },
        actionLabel: 'Allow access',
        onRetry: () =>
            ref.read(mediaLibraryProvider.notifier).requestAccess(kind: _kind),
        secondaryLabel: 'App settings',
        onSecondary: () =>
            ref.read(localMediaRepositoryProvider).openAppSettings(),
      );
    }

    final query = _searchController.text;
    final filtered = MediaLibraryQuery.searchAndSort(
      switch (widget.destination) {
        AppDestination.videos => snapshot.videos,
        AppDestination.music => snapshot.music,
        _ => snapshot.items,
      },
      query: query,
      sort: _sort,
    );
    final folders = MediaLibraryQuery.searchFolders(
      snapshot.folders,
      query: query,
    );
    final isFolders = widget.destination == AppDestination.folders;
    final empty = isFolders ? folders.isEmpty : filtered.isEmpty;
    final partial =
        access.videos == MediaAccessLevel.limited ||
        (widget.destination == AppDestination.folders &&
            (videoDenied || audioDenied));

    return Column(
      children: [
        if (partial)
          _AccessBanner(
            message: access.videos == MediaAccessLevel.limited
                ? 'Showing selected videos only.'
                : 'Some media is hidden because access is limited.',
            onManage: () =>
                ref.read(mediaLibraryProvider.notifier).requestAccess(),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(mediaLibraryProvider.notifier).refresh(),
            child: empty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      MediaStatePanel(
                        status: MediaViewStatus.empty,
                        icon: query.trim().isNotEmpty
                            ? Icons.search_off_rounded
                            : isFolders
                            ? Icons.folder_open_rounded
                            : widget.destination == AppDestination.videos
                            ? Icons.movie_outlined
                            : Icons.music_note_rounded,
                        message: query.trim().isNotEmpty
                            ? 'No media matches your search.'
                            : isFolders
                            ? 'No media folders found yet.'
                            : widget.destination == AppDestination.videos
                            ? 'No videos found yet.'
                            : 'No music found yet.',
                        actionLabel: 'Import media',
                        onRetry: canImport && query.trim().isEmpty
                            ? _import
                            : null,
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: isFolders ? folders.length : filtered.length,
                    itemBuilder: (context, index) => isFolders
                        ? _FolderTile(folder: folders[index])
                        : MediaListTile(media: filtered[index]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _LibraryControls extends StatelessWidget {
  const _LibraryControls({
    required this.searchController,
    required this.sort,
    required this.showSort,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  final TextEditingController searchController;
  final MediaSort sort;
  final bool showSort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<MediaSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search ${showSort ? 'media' : 'folders'}',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: GeeColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: GeeColors.outline),
              ),
            ),
          ),
          if (showSort) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Sort by',
                  style: TextStyle(color: GeeColors.textMuted),
                ),
                const SizedBox(width: 10),
                DropdownButton<MediaSort>(
                  value: sort,
                  underline: const SizedBox.shrink(),
                  onChanged: (value) {
                    if (value != null) onSortChanged(value);
                  },
                  items: const [
                    DropdownMenuItem(
                      value: MediaSort.newest,
                      child: Text('Date added'),
                    ),
                    DropdownMenuItem(
                      value: MediaSort.name,
                      child: Text('Name'),
                    ),
                    DropdownMenuItem(
                      value: MediaSort.duration,
                      child: Text('Duration'),
                    ),
                    DropdownMenuItem(
                      value: MediaSort.size,
                      child: Text('File size'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AccessBanner extends StatelessWidget {
  const _AccessBanner({required this.message, required this.onManage});

  final String message;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: GeeColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 19,
            color: GeeColors.accentLight,
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
          TextButton(onPressed: onManage, child: const Text('Manage')),
        ],
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.folder});

  final MediaFolder folder;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: GeeColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(
          Icons.folder_rounded,
          color: GeeColors.accentLight,
          size: 32,
        ),
        title: Text(folder.name),
        subtitle: Text('${folder.items.length} media files • ${folder.path}'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => _FolderContentsScreen(folder: folder),
          ),
        ),
      ),
    );
  }
}

class _FolderContentsScreen extends StatelessWidget {
  const _FolderContentsScreen({required this.folder});

  final MediaFolder folder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(folder.name)),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: folder.items.length,
          itemBuilder: (context, index) =>
              MediaListTile(media: folder.items[index]),
        ),
      ),
    );
  }
}
