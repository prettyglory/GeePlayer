import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/app/media_library_providers.dart';
import 'package:gee_player/app/media_collections_providers.dart';
import 'package:gee_player/data/playback/playback_database.dart';
import 'package:gee_player/presentation/screens/app_shell.dart';

import '../support/fake_media_repository.dart';

void main() {
  testWidgets('library refreshes when the app resumes', (tester) async {
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
    await tester.pumpAndSettle();
    final before = repository.loadCount;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(repository.loadCount, greaterThan(before));
  });

  testWidgets('phone navigation reaches every destination', (tester) async {
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
    expect(find.byType(NavigationBar), findsOneWidget);

    for (final (icon, message) in [
      (Icons.movie_outlined, 'No videos found yet.'),
      (Icons.music_note_outlined, 'No music found yet.'),
      (Icons.folder_outlined, 'No media folders found yet.'),
      (
        Icons.favorite_border_rounded,
        'Media you mark as a favorite will appear here.',
      ),
      (Icons.settings_outlined, 'Subtitles'),
    ]) {
      await tester.tap(find.byIcon(icon).first);
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
    }
  });

  testWidgets('landscape layout uses navigation rail', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
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
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byIcon(Icons.movie_outlined).first);
    await tester.pumpAndSettle();
    expect(find.text('No videos found yet.'), findsOneWidget);
  });
}
