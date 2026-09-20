# Gee Player

Gee Player is a Flutter application for playing locally stored video and music on Android and iOS. Automatic subtitle discovery through SubDL is planned. Local playback is intended to work without a network connection.

## Project status

The Phase 3 media library implementation is in place. Gee Player has branded launch screens, a dark Home dashboard, and navigation for Home, Videos, Music, Folders, Favorites, and Settings. Android discovers indexed videos and audio through MediaStore. On iOS, users choose video and audio files with the system picker; Gee Player copies supported files into its own app storage. Playback, subtitles, playlists, favorites, history, and functional settings are planned for later phases.

## Current interface

- Phone layouts use bottom navigation. Wider layouts use a scrollable navigation rail.
- Home previews recently added videos, music, and folders from the current library. Continue watching and Recently played will use playback history in later phases.
- Videos and Music show title, format, duration when available, file size, and folder. Search covers title, artist, and folder; sorting supports date added, name, duration, and size.
- Folders group accessible media and open a list of their contents. Android tiles display video thumbnails and embedded audio artwork when available.
- Android permission requests are scoped to video or audio. The UI handles denial, partial video access, retry, and a link to Android App Settings. The library refreshes when the app returns to the foreground.
- iOS provides an Import media action and keeps selected files in app support storage for later launches.
- Reusable media state widgets support loading, empty, and error messages with an optional retry action.
- Native Android and iOS branding assets can be regenerated on Windows with `powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\generate_brand_assets.ps1`.

## Planned technology

- Flutter and Dart for the application.
- `media_kit` and `media_kit_video` for playback, subject to platform and codec verification.
- Dio for subtitle network requests.
- Drift with SQLite for structured local data.
- `shared_preferences` for non-sensitive settings and `flutter_secure_storage` for a user-provided SubDL API key.
- `flutter_riverpod` 3.4.3 for asynchronous library state and dependency injection.
- `file_selector` 1.1.0 for user-selected iOS files, and `path_provider` 2.1.6 for app support storage.

The playback, network, database, and settings packages above have not been added yet. Their versions, licenses, maintenance, and platform support will be checked before installation. The installed packages were checked against their [Riverpod](https://pub.dev/packages/flutter_riverpod), [file_selector](https://pub.dev/packages/file_selector), and [path_provider](https://pub.dev/packages/path_provider) package pages on 2026-09-20.

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
flutter pub get
flutter devices
```

Connect an Android phone with USB debugging enabled or start an Android emulator, then run `flutter run`. A connected Android device is not required to edit or analyze the project.

## Android device check for Phase 3

With a phone or emulator connected, run `flutter devices` and `flutter run -d DEVICE_ID`. On the device:

1. Open Videos, grant video access, and confirm local videos and folders appear. Open Music separately to grant audio access.
2. Try search and all four sort choices, then open a folder to inspect its files.
3. Deny access, use App settings to grant it, return to Gee Player, and confirm the library refreshes.
4. Add or delete a media file outside Gee Player, return to the app, and confirm the list updates. On Android 14 or later, also test access to selected videos only.

These steps still need a connected device; they have not been run in the current Windows environment.

## Quality checks

Run `flutter analyze` and `flutter test` after changes. Tests cover media mapping, import persistence, search and sorting, permissions, folder navigation, Home previews, and foreground refresh. A development APK can be built with `flutter build apk --debug`; release signing and release builds will be verified in a later phase.

## API configuration

The SubDL integration and functional Settings screen are planned for later phases. No API key is required for the current interface. When implemented, users will enter their own key in Settings; keys must not be committed to Git or packaged into the app. A key stored on a client device cannot be completely secret from a determined attacker.

## Builds and platform notes

The Android application ID and iOS bundle ID are `com.gee.player`. The Android project currently uses Flutter's generated debug signing configuration for release builds; distribution signing has not been configured. No release APK has been produced.

Building and signing the iOS application requires macOS with Xcode or a compatible macOS-based build service. The iOS project is generated, but it cannot be built or verified on Windows.

## Known limitations

- Media list entries do not play files yet. Playback and resume controls are Phase 4 work; local subtitle discovery and loading are Phase 5 work.
- Android MediaStore shows indexed video and audio that the user has granted access to. Android 14 and later can grant access to selected videos only. [Android media access](https://developer.android.com/training/data-storage/shared/media) and [partial video access](https://developer.android.com/about/versions/14/changes/partial-photo-video-access) explain these platform rules. Files outside the indexed collections and subtitle files are not included in this scan.
- iOS has no automatic device-wide media scan. The picker copies selected files into Gee Player storage, which uses additional space. The current iOS library has one virtual Imported media folder and uses file modification time for its date. Duration and artwork are not extracted from imported iOS files yet; a format icon is shown instead. [file_selector's platform support](https://pub.dev/packages/file_selector) does not include iOS directory picking.
- Video thumbnails and embedded audio artwork are best effort on Android. Files without readable artwork show a format icon. Codec support and playback behavior have not been verified.
- Android debug compilation and automated tests passed on Windows. No Android device or emulator was available for runtime testing. The iOS project and file import path have not been built or tested on iPhone because this Windows environment cannot run Xcode.
