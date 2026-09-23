import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/app/application_settings_providers.dart';
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
  });
}
