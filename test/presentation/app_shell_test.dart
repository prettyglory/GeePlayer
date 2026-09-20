import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/presentation/screens/app_shell.dart';

void main() {
  testWidgets('phone navigation reaches every destination', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    expect(find.byType(NavigationBar), findsOneWidget);

    for (final (icon, message) in [
      (
        Icons.movie_outlined,
        'Your local videos will appear here once media discovery is ready.',
      ),
      (
        Icons.music_note_outlined,
        'Your local music will appear here once media discovery is ready.',
      ),
      (
        Icons.folder_outlined,
        'Browse your accessible media folders here in the next phase.',
      ),
      (
        Icons.favorite_border_rounded,
        'Media you mark as a favorite will appear here.',
      ),
      (
        Icons.settings_outlined,
        'Playback, subtitle, and app preferences are coming in a later phase.',
      ),
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

    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byIcon(Icons.movie_outlined).first);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Your local videos will appear here once media discovery is ready.',
      ),
      findsOneWidget,
    );
  });
}
