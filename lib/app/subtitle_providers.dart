import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/playback_providers.dart';
import 'package:gee_player/app/subtitle_controller.dart';
import 'package:gee_player/data/subtitles/android_companion_subtitle_finder.dart';
import 'package:gee_player/data/subtitles/subdl_provider.dart';
import 'package:gee_player/data/subtitles/subtitle_preferences.dart';
import 'package:gee_player/data/subtitles/subtitle_store.dart';
import 'package:gee_player/domain/subtitles/subtitle_candidate.dart';

final subtitlePreferencesProvider = Provider<SubtitlePreferences>(
  (ref) => SubtitlePreferences(),
);
final subtitleStoreProvider = Provider<SubtitleStore>((ref) => SubtitleStore());
final subtitleProvider = Provider<SubtitleProvider>((ref) => SubdlProvider());
final companionSubtitleFinderProvider = Provider<CompanionSubtitleFinder>(
  (ref) => const AndroidCompanionSubtitleFinder(),
);

final subtitleAppearanceProvider =
    AsyncNotifierProvider<SubtitleAppearanceController, SubtitleAppearance>(
      SubtitleAppearanceController.new,
      retry: (retryCount, error) => null,
    );

class SubtitleAppearanceController extends AsyncNotifier<SubtitleAppearance> {
  SubtitlePreferences get _preferences => ref.read(subtitlePreferencesProvider);

  @override
  Future<SubtitleAppearance> build() => _preferences.appearance();

  Future<void> saveAppearance(SubtitleAppearance appearance) async {
    state = AsyncData(appearance);
    await _preferences.setAppearance(appearance);
    final playback = ref.read(playbackControllerProvider);
    await playback.setSubtitleDelay(
      Duration(milliseconds: appearance.delayMilliseconds),
    );
  }
}

final subtitleControllerProvider = Provider<SubtitleController>((ref) {
  final controller = SubtitleController(
    ref.watch(playbackControllerProvider),
    ref.watch(subtitleStoreProvider),
    ref.watch(subtitlePreferencesProvider),
    ref.watch(subtitleProvider),
    ref.watch(companionSubtitleFinderProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
