# Gee Player

Gee Player is a Flutter application for playing locally stored video and music on Android and iOS. Automatic subtitle discovery through SubDL is planned. Local playback is intended to work without a network connection.

## Project status

Phases 1 and 2 are complete. Gee Player now has native app icons and launch screens, an animated splash, a dark theme, responsive Home dashboard, and navigation for Home, Videos, Music, Folders, Favorites, and Settings. The Home dashboard shows honest empty states until local media discovery is implemented. The other destinations currently explain when their features will be added. Media discovery, playback, subtitles, playlists, and functional settings are planned for later phases.

## Current interface

- Phone layouts use bottom navigation. Wider layouts use a scrollable navigation rail.
- Home provides quick links and sections for Continue watching, Recently played, Recently added videos, Recently added music, and Media folders.
- Reusable media state widgets support loading, empty, and error messages with an optional retry action.
- Native Android and iOS branding assets can be regenerated on Windows with `powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\generate_brand_assets.ps1`.

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

Run `flutter analyze` and `flutter test` after changes. Widget tests cover splash handoff, responsive navigation, Home sections, and the error retry action. A development APK can be built with `flutter build apk --debug`; release signing and release builds will be verified in a later phase.

## API configuration

The SubDL integration and functional Settings screen are planned for later phases. No API key is required for the current interface. When implemented, users will enter their own key in Settings; keys must not be committed to Git or packaged into the app. A key stored on a client device cannot be completely secret from a determined attacker.

## Builds and platform notes

The Android application ID and iOS bundle ID are `com.gee.player`. The Android project currently uses Flutter's generated debug signing configuration for release builds; distribution signing has not been configured. No release APK has been produced.

Building and signing the iOS application requires macOS with Xcode or a compatible macOS-based build service. The iOS project is generated, but it cannot be built or verified on Windows.

## Known limitations

The current interface does not yet scan or play media. Android and iOS codec support, media access, background playback, subtitles, and provider behavior remain to be implemented and verified in their respective phases. Native iOS launch assets have been prepared, but the iOS build and on-device appearance have not been verified on Windows.
