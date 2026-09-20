import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/playback_controller.dart';
import 'package:gee_player/data/playback/playback_database.dart';
import 'package:gee_player/data/playback/playback_source_resolver.dart';

final playbackControllerProvider = Provider<PlaybackController>((ref) {
  final controller = PlaybackController(
    PlaybackDatabase.new,
    const PlaybackSourceResolver(),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
