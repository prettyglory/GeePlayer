import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/presentation/screens/app_shell.dart';
import 'package:gee_player/presentation/widgets/media_state_panel.dart';

void main() {
  testWidgets('home shows all media sections and opens a library tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AppShell()));

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
    expect(
      find.text(
        'Your local videos will appear here once media discovery is ready.',
      ),
      findsOneWidget,
    );
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
