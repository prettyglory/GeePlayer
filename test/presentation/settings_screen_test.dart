import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/app/application_settings_providers.dart';
import 'package:gee_player/app/subtitle_providers.dart';
import 'package:gee_player/data/subtitles/subtitle_store.dart';
import 'package:gee_player/presentation/screens/settings_screen.dart';

import '../support/fake_application_preferences.dart';

void main() {
  testWidgets('general settings are persisted and subtitles remain available', (
    tester,
  ) async {
    final preferences = FakeApplicationPreferences();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          applicationPreferencesProvider.overrideWithValue(preferences),
          subtitleCacheInfoProvider.overrideWith(
            _FakeSubtitleCacheController.new,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Playback'), findsOneWidget);

    await tester.tap(find.text('Pure black theme'));
    await tester.pumpAndSettle();

    expect(preferences.settings.pureBlackTheme, isTrue);

    await tester.tap(find.text('Subtitles'));
    await tester.pumpAndSettle();

    expect(find.text('SubDL API key'), findsOneWidget);
    expect(find.text('Subtitle appearance'), findsOneWidget);

    await tester.tap(find.text('Storage'));
    await tester.pumpAndSettle();

    expect(find.text('App storage'), findsOneWidget);
    expect(find.text('Clear subtitle cache'), findsOneWidget);

    await tester.tap(find.text('Clear subtitle cache'));
    await tester.pumpAndSettle();
    expect(find.text('Clear cached subtitles?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pumpAndSettle();

    expect(find.text('No cached subtitles'), findsOneWidget);
  });

  testWidgets('resetting general settings requires confirmation', (
    tester,
  ) async {
    final preferences = FakeApplicationPreferences();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          applicationPreferencesProvider.overrideWithValue(preferences),
          subtitleCacheInfoProvider.overrideWith(
            _FakeSubtitleCacheController.new,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pure black theme'));
    await tester.pumpAndSettle();
    expect(preferences.settings.pureBlackTheme, isTrue);

    final resetButton = find.text('Reset general settings');
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(resetButton);
    await tester.pumpAndSettle();

    expect(find.text('Reset general settings?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(preferences.settings.pureBlackTheme, isTrue);

    await tester.tap(resetButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    expect(preferences.settings.pureBlackTheme, isFalse);
    expect(find.text('General settings reset.'), findsOneWidget);
  });
}

class _FakeSubtitleCacheController extends SubtitleCacheController {
  @override
  Future<SubtitleCacheInfo> build() async =>
      const SubtitleCacheInfo(fileCount: 2, totalBytes: 2048);

  @override
  Future<void> clear() async {
    state = const AsyncData(SubtitleCacheInfo.empty());
  }
}
