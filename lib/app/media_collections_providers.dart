import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/data/playback/playback_database.dart';
import 'package:gee_player/domain/media/local_media.dart';

final playbackDatabaseProvider = Provider<PlaybackDatabase>((ref) {
  final database = PlaybackDatabase();
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

final mediaCollectionsProvider =
    AsyncNotifierProvider<MediaCollectionsController, MediaCollectionsState>(
      MediaCollectionsController.new,
      retry: (retryCount, error) => null,
    );

class MediaCollectionsState {
  const MediaCollectionsState({
    required this.favoriteIds,
    required this.favorites,
    required this.playlists,
    required this.recent,
    required this.continueWatching,
  });

  final Set<String> favoriteIds;
  final List<LocalMedia> favorites;
  final List<SavedPlaylist> playlists;
  final List<LocalMedia> recent;
  final List<ContinueWatchingItem> continueWatching;
}

class MediaCollectionsController extends AsyncNotifier<MediaCollectionsState> {
  PlaybackDatabase get _database => ref.read(playbackDatabaseProvider);

  @override
  Future<MediaCollectionsState> build() => _load();

  Future<MediaCollectionsState> _load() async {
    final results = await Future.wait<Object>([
      _database.favoriteIds(),
      _database.favoriteItems(),
      _database.savedPlaylists(),
      _database.recentMedia(),
      _database.continueWatching(),
    ]);
    return MediaCollectionsState(
      favoriteIds: results[0] as Set<String>,
      favorites: results[1] as List<LocalMedia>,
      playlists: results[2] as List<SavedPlaylist>,
      recent: results[3] as List<LocalMedia>,
      continueWatching: results[4] as List<ContinueWatchingItem>,
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  Future<void> toggleFavorite(LocalMedia media) async {
    await _database.toggleFavorite(media);
    await refresh();
  }

  Future<String?> createPlaylist(String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return null;
    final id = await _database.createPlaylist(cleaned);
    await refresh();
    return id;
  }

  Future<void> renamePlaylist(String id, String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;
    await _database.renamePlaylist(id, cleaned);
    await refresh();
  }

  Future<void> deletePlaylist(String id) async {
    await _database.deletePlaylist(id);
    await refresh();
  }

  Future<void> addToPlaylist(String playlistId, LocalMedia media) async {
    await _database.addToPlaylist(playlistId, media);
    await refresh();
  }

  Future<void> removeFromPlaylist(String playlistId, String mediaId) async {
    await _database.removeFromPlaylist(playlistId, mediaId);
    await refresh();
  }

  Future<List<LocalMedia>> playlistMedia(String playlistId) =>
      _database.playlistMedia(playlistId);

  Future<void> clearHistory() async {
    await _database.clearHistory();
    await refresh();
  }
}
