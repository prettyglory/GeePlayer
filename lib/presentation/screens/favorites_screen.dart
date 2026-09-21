import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/media_collections_providers.dart';
import 'package:gee_player/data/playback/playback_database.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/presentation/screens/playback_screen.dart';
import 'package:gee_player/presentation/widgets/media_actions_button.dart';
import 'package:gee_player/presentation/widgets/media_list_tile.dart';
import 'package:gee_player/presentation/widgets/media_state_panel.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(mediaCollectionsProvider);
    return SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your collection',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: () =>
                        ref.read(mediaCollectionsProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Favorites'),
                Tab(text: 'Playlists'),
                Tab(text: 'History'),
              ],
            ),
            Expanded(
              child: switch (collections) {
                AsyncData(:final value) => TabBarView(
                  children: [
                    _MediaCollection(
                      items: value.favorites,
                      emptyMessage:
                          'Media you mark as a favorite will appear here.',
                    ),
                    _Playlists(playlists: value.playlists),
                    _History(items: value.recent),
                  ],
                ),
                AsyncError() => MediaStatePanel(
                  status: MediaViewStatus.error,
                  message: 'Could not load your saved media.',
                  onRetry: () =>
                      ref.read(mediaCollectionsProvider.notifier).refresh(),
                ),
                _ => const MediaStatePanel(
                  status: MediaViewStatus.loading,
                  message: 'Loading your collection…',
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaCollection extends StatelessWidget {
  const _MediaCollection({required this.items, required this.emptyMessage});

  final List<LocalMedia> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return MediaStatePanel(
        status: MediaViewStatus.empty,
        icon: Icons.favorite_border_rounded,
        message: emptyMessage,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) => MediaListTile(
        media: items[index],
        trailing: MediaActionsButton(media: items[index]),
        onTap: () => _openMedia(context, items, items[index]),
      ),
    );
  }
}

class _Playlists extends ConsumerWidget {
  const _Playlists({required this.playlists});

  final List<SavedPlaylist> playlists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FilledButton.icon(
          onPressed: () async {
            final name = await showPlaylistNameDialog(context);
            if (name != null) {
              await ref
                  .read(mediaCollectionsProvider.notifier)
                  .createPlaylist(name);
            }
          },
          icon: const Icon(Icons.playlist_add_rounded),
          label: const Text('Create playlist'),
        ),
        const SizedBox(height: 12),
        if (playlists.isEmpty)
          const MediaStatePanel(
            status: MediaViewStatus.empty,
            icon: Icons.queue_music_rounded,
            message: 'Create a playlist to organize your music and videos.',
          ),
        for (final playlist in playlists)
          Card(
            child: ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: Text(playlist.name),
              subtitle: Text('${playlist.itemCount} media files'),
              trailing: PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'rename') {
                    final name = await showPlaylistNameDialog(
                      context,
                      title: 'Rename playlist',
                      initialValue: playlist.name,
                    );
                    if (name != null) {
                      await ref
                          .read(mediaCollectionsProvider.notifier)
                          .renamePlaylist(playlist.id, name);
                    }
                  } else if (action == 'delete') {
                    await ref
                        .read(mediaCollectionsProvider.notifier)
                        .deletePlaylist(playlist.id);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlaylistScreen(playlist: playlist),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _History extends ConsumerWidget {
  const _History({required this.items});

  final List<LocalMedia> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const MediaStatePanel(
        status: MediaViewStatus.empty,
        icon: Icons.history_rounded,
        message: 'Your playback history will appear here.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () =>
                ref.read(mediaCollectionsProvider.notifier).clearHistory(),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Clear history'),
          ),
        ),
        for (final media in items)
          MediaListTile(
            media: media,
            trailing: MediaActionsButton(media: media),
            onTap: () => _openMedia(context, items, media),
          ),
      ],
    );
  }
}

class PlaylistScreen extends ConsumerStatefulWidget {
  const PlaylistScreen({required this.playlist, super.key});

  final SavedPlaylist playlist;

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen> {
  late Future<List<LocalMedia>> _items;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _items = ref
        .read(mediaCollectionsProvider.notifier)
        .playlistMedia(widget.playlist.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
      body: FutureBuilder<List<LocalMedia>>(
        future: _items,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const MediaStatePanel(
              status: MediaViewStatus.empty,
              icon: Icons.playlist_add_rounded,
              message: 'Add media to this playlist from your library.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) => MediaListTile(
              media: items[index],
              trailing: IconButton(
                tooltip: 'Remove from playlist',
                onPressed: () async {
                  await ref
                      .read(mediaCollectionsProvider.notifier)
                      .removeFromPlaylist(widget.playlist.id, items[index].id);
                  setState(_reload);
                },
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              onTap: () => _openMedia(context, items, items[index]),
            ),
          );
        },
      ),
    );
  }
}

void _openMedia(
  BuildContext context,
  List<LocalMedia> items,
  LocalMedia selected,
) {
  final queue = items.where((item) => item.kind == selected.kind).toList();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlaybackScreen(
        queue: queue,
        index: queue.indexWhere((item) => item.id == selected.id),
      ),
    ),
  );
}
