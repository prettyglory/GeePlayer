import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/media_collections_providers.dart';
import 'package:gee_player/domain/media/local_media.dart';

class MediaActionsButton extends ConsumerWidget {
  const MediaActionsButton({required this.media, super.key});

  final LocalMedia media;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(mediaCollectionsProvider).value;
    final favorite = collections?.favoriteIds.contains(media.id) ?? false;
    return PopupMenuButton<_MediaAction>(
      tooltip: 'Media actions',
      onSelected: (action) async {
        if (action == _MediaAction.favorite) {
          await ref
              .read(mediaCollectionsProvider.notifier)
              .toggleFavorite(media);
        } else {
          if (context.mounted) await showAddToPlaylist(context, ref, media);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _MediaAction.favorite,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            ),
            title: Text(favorite ? 'Remove favorite' : 'Add to favorites'),
          ),
        ),
        const PopupMenuItem(
          value: _MediaAction.playlist,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.playlist_add_rounded),
            title: Text('Add to playlist'),
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert_rounded),
    );
  }
}

enum _MediaAction { favorite, playlist }

Future<String?> showPlaylistNameDialog(
  BuildContext context, {
  String title = 'New playlist',
  String initialValue = '',
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (_) =>
        _PlaylistNameDialog(title: title, initialValue: initialValue),
  );
  return result?.trim().isEmpty ?? true ? null : result!.trim();
}

class _PlaylistNameDialog extends StatefulWidget {
  const _PlaylistNameDialog({required this.title, required this.initialValue});

  final String title;
  final String initialValue;

  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(labelText: 'Playlist name'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, child) => FilledButton(
            onPressed: value.text.trim().isEmpty ? null : _submit,
            child: child,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

Future<void> showAddToPlaylist(
  BuildContext context,
  WidgetRef ref,
  LocalMedia media,
) async {
  final collections = await ref.read(mediaCollectionsProvider.future);
  if (!context.mounted) return;
  final playlistId = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text(
              'Add to playlist',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          for (final playlist in collections.playlists)
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: Text(playlist.name),
              subtitle: Text('${playlist.itemCount} tracks'),
              onTap: () => Navigator.pop(context, playlist.id),
            ),
          ListTile(
            leading: const Icon(Icons.add_rounded),
            title: const Text('Create playlist'),
            onTap: () => Navigator.pop(context, '__new__'),
          ),
        ],
      ),
    ),
  );
  if (playlistId == null || !context.mounted) return;
  var target = playlistId;
  if (target == '__new__') {
    final name = await showPlaylistNameDialog(context);
    if (name == null) return;
    target =
        await ref
            .read(mediaCollectionsProvider.notifier)
            .createPlaylist(name) ??
        '';
  }
  if (target.isEmpty) return;
  await ref
      .read(mediaCollectionsProvider.notifier)
      .addToPlaylist(target, media);
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Added to playlist')));
  }
}
