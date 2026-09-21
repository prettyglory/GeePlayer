import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/background_audio_handler.dart';
import 'package:gee_player/app/gee_player_app.dart';
import 'package:gee_player/app/playback_providers.dart';
import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  final audioHandler = await AudioService.init<GeeAudioHandler>(
    builder: GeeAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.gee.player.playback',
      androidNotificationChannelName: 'Gee Player playback',
      androidNotificationChannelDescription:
          'Music playback controls and progress',
      androidStopForegroundOnPause: false,
    ),
  );
  await audioHandler.initializeSession();
  runApp(
    ProviderScope(
      overrides: [audioHandlerProvider.overrideWithValue(audioHandler)],
      child: const GeePlayerApp(),
    ),
  );
}
