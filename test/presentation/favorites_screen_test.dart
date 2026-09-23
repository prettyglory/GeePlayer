import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/app/media_collections_providers.dart';
import 'package:gee_player/app/media_library_providers.dart';
import 'package:gee_player/data/playback/playback_database.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/presentation/screens/favorites_screen.dart';

import '../support/fake_media_repository.dart';

void main() {
  testWidgets('playlist name must contain visible characters', (tester) async {
    final database = PlaybackDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playbackDatabaseProvider.overrideWithValue(database),
          localMediaRepositoryProvider.overrideWith(
            (ref) => FakeMediaRepository(snapshot: emptyAccessibleLibrary()),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: FavoritesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Playlists'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create playlist'));
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(FilledButton, 'Save');
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Road trip');
    await tester.pump();
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);

    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.text('Road trip'), findsOneWidget);
  });

  testWidgets('clearing playback history requires confirmation', (
    tester,
  ) async {
    final database = PlaybackDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    const song = LocalMedia(
      id: 'audio:history',
      kind: MediaKind.audio,
      uri: 'content://audio/history',
      fileName: 'Remember Me.mp3',
      folderPath: 'Music',
    );
    await database.recordPlayback(song);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playbackDatabaseProvider.overrideWithValue(database),
          localMediaRepositoryProvider.overrideWith(
            (ref) => FakeMediaRepository(snapshot: emptyAccessibleLibrary()),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: FavoritesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Remember Me'), findsOneWidget);

    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();
    expect(find.text('Clear playback history?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await database.recentMedia(), isNotEmpty);

    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pumpAndSettle();

    expect(await database.recentMedia(), isEmpty);
    expect(
      find.text('Your playback history will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets('playlist screen exposes a drag handle for every item', (
    tester,
  ) async {
    final database = PlaybackDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final playlistId = await database.createPlaylist('Road trip');
    for (final song in const [
      LocalMedia(
        id: 'audio:one',
        kind: MediaKind.audio,
        uri: 'content://audio/one',
        fileName: 'One.mp3',
        folderPath: 'Music',
      ),
      LocalMedia(
        id: 'audio:two',
        kind: MediaKind.audio,
        uri: 'content://audio/two',
        fileName: 'Two.mp3',
        folderPath: 'Music',
      ),
    ]) {
      await database.addToPlaylist(playlistId, song);
    }
    final playlist = (await database.savedPlaylists()).single;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playbackDatabaseProvider.overrideWithValue(database),
          localMediaRepositoryProvider.overrideWith(
            (ref) => FakeMediaRepository(snapshot: emptyAccessibleLibrary()),
          ),
        ],
        child: MaterialApp(home: PlaylistScreen(playlist: playlist)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(2));
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
  });
}
