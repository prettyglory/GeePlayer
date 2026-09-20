# Gee Player

Gee Player is a Flutter application for playing locally stored video and music on Android and iOS. Automatic subtitle discovery through SubDL is planned. Local playback is intended to work without a network connection.

## Project status

Phase 1 establishes the Flutter project, native application identifiers, and source layout. The app currently opens a placeholder screen. Media discovery, playback, subtitles, playlists, settings, and the final design have not been implemented.

## Planned technology

- Flutter and Dart for the application.
- `media_kit` and `media_kit_video` for playback, subject to platform and codec verification.
- Dio for subtitle network requests.
- Drift with SQLite for structured local data.
- `shared_preferences` for non-sensitive settings and `flutter_secure_storage` for a user-provided SubDL API key.
- `flutter_riverpod` for state management and dependency injection as features are added. Its async state handling and provider overrides fit the media library, playback, and subtitle services.

These packages have not been added yet. Versions, licenses, maintenance, and platform support will be checked before each is installed.

## Source layout

| Directory | Purpose |
| --- | --- |
| `lib/app` | Application bootstrap and composition |
| `lib/presentation` | Screens, widgets, navigation, and state presentation |
| `lib/domain` | Media and subtitle models, contracts, and use cases |
| `lib/data` | Device access, storage, and remote provider implementations |
| `lib/core` | Small services shared across features |

## Setup and running

Install the Flutter SDK, the Flutter and Dart VS Code extensions, and the Android SDK with Platform-Tools, Build-Tools, and Command-line Tools. Check your installation and accept any required Android licenses:

```powershell
flutter doctor -v
flutter doctor --android-licenses
flutter pub get
flutter devices
```

Connect an Android phone with USB debugging enabled or start an Android emulator, then run `flutter run`. A connected Android device is not required to edit or analyze the project.

## Quality checks

Run `flutter analyze` after changes. A development APK can be built with `flutter build apk --debug`; this Phase 1 build has been verified on Windows. Automated tests will be added with the features they verify and run with `flutter test`. Release signing and release builds will be verified in a later phase.

## API configuration

The SubDL integration and Settings screen are planned for later phases. No API key is required for this placeholder app. When implemented, users will enter their own key in Settings; keys must not be committed to Git or packaged into the app. A key stored on a client device cannot be completely secret from a determined attacker.

## Builds and platform notes

The Android application ID and iOS bundle ID are `com.gee.player`. The Android project currently uses Flutter's generated debug signing configuration for release builds; distribution signing has not been configured. No release APK has been produced.

Building and signing the iOS application requires macOS with Xcode or a compatible macOS-based build service. The iOS project is generated, but it cannot be built or verified on Windows.

## Known limitations

The current screen is a placeholder. Android and iOS codec support, media access, background playback, subtitles, and provider behavior remain to be implemented and verified in their respective phases.
