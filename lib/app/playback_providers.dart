import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/background_audio_handler.dart';
import 'package:gee_player/app/application_settings_providers.dart';
import 'package:gee_player/app/media_collections_providers.dart';
import 'package:gee_player/app/playback_controller.dart';
import 'package:gee_player/data/playback/playback_source_resolver.dart';

final audioHandlerProvider = Provider<GeeAudioHandler>(
  (ref) => GeeAudioHandler(),
);

final playbackControllerProvider = Provider<PlaybackController>((ref) {
  final controller = PlaybackController(
    ref.watch(playbackDatabaseProvider),
    const PlaybackSourceResolver(),
    applicationPreferences: ref.watch(applicationPreferencesProvider),
    audioHandler: ref.watch(audioHandlerProvider),
    onHistoryChanged: () => ref.invalidate(mediaCollectionsProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
