import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/app/media_library_providers.dart';
import 'package:gee_player/app/media_collections_providers.dart';
import 'package:gee_player/data/playback/playback_database.dart';
import 'package:gee_player/domain/media/library_snapshot.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/presentation/navigation/app_destination.dart';
import 'package:gee_player/presentation/screens/media_library_screen.dart';

import '../support/fake_media_repository.dart';

void main() {
  const trip = LocalMedia(
    id: 'video:1',
    kind: MediaKind.video,
    uri: 'content://video/1',
    fileName: 'Trip.mp4',
    folderPath: 'Movies/Travel',
    duration: Duration(minutes: 2),
    sizeBytes: 5000000,
  );
  const song = LocalMedia(
    id: 'audio:1',
    kind: MediaKind.audio,
    uri: 'content://audio/1',
    fileName: 'Song.mp3',
    folderPath: 'Music',
    artist: 'Artist',
  );

  testWidgets('video library shows metadata and filters search results', (
    tester,
  ) async {
    final repository = FakeMediaRepository(
      snapshot: const LibrarySnapshot(
        items: [trip, song],
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
        child: const MaterialApp(
          home: Scaffold(
            body: MediaLibraryScreen(destination: AppDestination.videos),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip'), findsOneWidget);
    expect(find.text('Song'), findsNothing);
    expect(find.textContaining('MP4'), findsOneWidget);
    expect(find.text('Movies/Travel'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();
    expect(find.text('No media matches your search.'), findsOneWidget);
  });

  testWidgets('video permission action requests video access only', (
    tester,
  ) async {
    final repository = FakeMediaRepository(
      snapshot: const LibrarySnapshot(
        items: [],
        access: MediaAccess(
          videos: MediaAccessLevel.denied,
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
        child: const MaterialApp(
          home: Scaffold(
            body: MediaLibraryScreen(destination: AppDestination.videos),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Allow access'));
    await tester.pumpAndSettle();
    expect(repository.requestedKind, MediaKind.video);

    await tester.tap(find.text('App settings'));
    expect(repository.openSettingsCount, 1);
  });

  testWidgets('folder opens its discovered media', (tester) async {
    final repository = FakeMediaRepository(
      snapshot: const LibrarySnapshot(
        items: [trip, song],
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
        child: const MaterialApp(
          home: Scaffold(
            body: MediaLibraryScreen(destination: AppDestination.folders),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Travel'));
    await tester.pumpAndSettle();
    expect(find.text('Trip'), findsOneWidget);
    expect(find.text('Song'), findsNothing);
  });
}
