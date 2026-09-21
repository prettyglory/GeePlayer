import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/app/media_library_providers.dart';
import 'package:gee_player/app/media_collections_providers.dart';
import 'package:gee_player/data/playback/playback_database.dart';
import 'package:gee_player/domain/media/library_snapshot.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/presentation/screens/app_shell.dart';
import 'package:gee_player/presentation/widgets/media_state_panel.dart';

import '../support/fake_media_repository.dart';

void main() {
  testWidgets('home previews discovered media and folders', (tester) async {
    final repository = FakeMediaRepository(
      snapshot: const LibrarySnapshot(
        items: [
          LocalMedia(
            id: 'video:1',
            kind: MediaKind.video,
            uri: 'content://video/1',
            fileName: 'Trip.mp4',
            folderPath: 'Movies/Travel',
          ),
          LocalMedia(
            id: 'audio:1',
            kind: MediaKind.audio,
            uri: 'content://audio/1',
            fileName: 'Song.mp3',
            folderPath: 'Music',
          ),
        ],
        access: MediaAccess(
          videos: MediaAccessLevel.granted,
          audio: MediaAccessLevel.granted,
        ),
      ),
    );
    final database = PlaybackDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localMediaRepositoryProvider.overrideWith((ref) => repository),
          playbackDatabaseProvider.overrideWithValue(database),
        ],
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip'), findsOneWidget);
    expect(find.text('Song'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
  });

  testWidgets('home shows all media sections and opens a library tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeMediaRepository(snapshot: emptyAccessibleLibrary());
    final database = PlaybackDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localMediaRepositoryProvider.overrideWith((ref) => repository),
          playbackDatabaseProvider.overrideWithValue(database),
        ],
        child: const MaterialApp(home: AppShell()),
      ),
    );

    for (final title in [
      'Continue watching',
      'Recently played',
      'Recently added videos',
      'Recently added music',
      'Media folders',
    ]) {
      expect(find.text(title), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('quick-videos')));
    await tester.pumpAndSettle();
    expect(find.text('No videos found yet.'), findsOneWidget);
  });

  testWidgets('media state panel gives a retry action for errors', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaStatePanel(
            status: MediaViewStatus.error,
            message: 'Could not load your media.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Could not load your media.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });
}
