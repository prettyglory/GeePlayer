import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/app/gee_player_app.dart';
import 'package:gee_player/app/media_library_providers.dart';
import 'package:gee_player/presentation/screens/app_shell.dart';
import 'package:gee_player/presentation/screens/splash_screen.dart';

import '../support/fake_media_repository.dart';

void main() {
  testWidgets('the branded splash hands off to the application', (
    tester,
  ) async {
    final repository = FakeMediaRepository(snapshot: emptyAccessibleLibrary());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localMediaRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: const GeePlayerApp(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Gee Player'), findsOneWidget);

    await tester.pump(SplashScreen.displayDuration);
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('Your media, your moment.'), findsOneWidget);
  });
}
