# Gee Player

Gee Player is an Android Flutter application for playing locally stored video and music, with offline subtitles and optional SubDL search. Local playback works without a network connection.

## Project status

The Phase 9 storage-management implementation is in place. Baseline permission, MediaStore discovery, audio playback, queue advance, video-player UI, restart, and license checks have passed on an Android 15 emulator; physical-device and representative-codec checks remain. See the [emulator validation report](docs/EMULATOR_VALIDATION.md). Gee Player has branded launch screens, a customizable dark Home dashboard, and navigation for Home, Videos, Music, Folders, Favorites, and Settings. Android discovers indexed videos and audio through MediaStore. Videos and songs can be opened from their library lists, saved as favorites, organized into playlists, and tracked in playback history.

## Current interface

- Phone layouts use bottom navigation. Wider layouts use a scrollable navigation rail.
- Home previews recently added videos, music, and folders, plus real Continue watching and Recently played data.
- Videos and Music show title, format, duration when available, file size, and folder. Search covers title, artist, and folder; sorting supports date added, name, duration, and size.
- Folders group accessible media and open a list of their contents. Android tiles display video thumbnails and embedded audio artwork when available.
- Video and music open a shared playback screen with play, pause, stop, seek, ten-second skip, speed, and remaining-time display. Video has audio-track selection, aspect ratio, fullscreen, screen lock, double-tap seeking, brightness and volume gestures, and Android Picture in Picture. Music has an editable playing queue, previous and next controls, shuffle, repeat-one or repeat-all, and a sleep timer. A mini-player remains in the app shell while navigating and shows an active sleep-timer countdown.
- Playback position is saved in a local Drift/SQLite database and restored when the same media is opened again. A position near the end is cleared so completed media restarts from the beginning.
- Video subtitles can be selected from embedded tracks, discovered beside the video when Android exposes an indexed subtitle file, imported from an Android file picker, or searched and downloaded from SubDL. Local and downloaded subtitles are stored in app support storage for later offline playback. A close release-name match can load automatically; ambiguous search results remain available for manual choice. Empty searches are remembered for 24 hours.
- Settings includes General, Subtitles, and Storage tabs. General preferences cover accent color, an OLED-friendly pure-black theme, default playback speed, resume behavior, background audio, video gestures, and a reset action. The Subtitles tab securely saves your own SubDL API key, controls automatic online search and language preference, and customizes subtitle size, colors, position, and timing. Storage reports cached subtitle usage, safely clears app-owned copies without deleting original media or external subtitle files, and links to bundled open-source license terms. Online search is off by default. Video playback continues during subtitle searches and downloads.
- Favorites, playlists, playback history, and Continue watching are stored in the local Drift database. Library and player menus can add media to a favorite or playlist, while the collection screen supports playlist reordering, rename, deletion, and confirmed history clearing.
- Music uses an Android foreground media service for playback with notification, lock-screen, headset-button, audio-focus, interruption, and headphone-disconnection handling.
- Android permission requests are scoped to video or audio. The UI handles denial, partial video access, retry, and a link to Android App Settings. The library refreshes when the app returns to the foreground.
- Reusable media state widgets support loading, empty, and error messages with an optional retry action.
- Android launcher icons can be regenerated on Windows with `powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\generate_brand_assets.ps1`.

## Technology

- Flutter and Dart for the application.
- `media_kit` 1.2.6, `media_kit_video` 2.0.1, and video native libraries for playback, subject to device and codec verification.
- Dio for subtitle network requests.
- Drift 2.35.0 with SQLite for playback progress.
- `shared_preferences` for non-sensitive settings and `flutter_secure_storage` for a user-provided SubDL API key.
- `flutter_riverpod` 3.4.3 for asynchronous library state and dependency injection.
- `media_kit_libs_android_video` 1.3.8 for Android video and audio native libraries.
- `audio_service` 0.18.19 and `audio_session` 0.2.4 for Android background media controls and audio focus.

The SubDL integration follows the [official search and download API](https://subdl.com/api-doc). The user supplies a personal key; no key is packaged with the app.

Before distributing a release, include the required notices for the bundled native media libraries. The [Android libmpv build](https://github.com/media-kit/libmpv-android-video-build) documents its component licenses.

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

The baseline permission, denial/retry, full-access, refresh, and indexed-media discovery flows passed on an Android 15 emulator. Selected-video-only access and the Android App Settings round trip still need a physical-device pass.

## Device check for Phase 4

With a phone or emulator connected, play a local video from Videos and a song from Music. Verify pause, seek, skip, stop, speed, fullscreen rotation, and the mini-player. Play a song from a folder and check that Next stays within audio files. Pause a video after at least five seconds, close and reopen the app, then tap the same video to verify resume. Play to the end and reopen it to verify it starts at the beginning. Test an unsupported or damaged file to confirm an error appears without an app crash. Indexed WAV playback and automatic queue advance passed on the Android 15 emulator; the remaining runtime checks still require representative media and a physical device.

## Device check for Phase 5

Open a video with an embedded subtitle and switch tracks from the Subtitles panel. Place a same-named SRT beside a video in an indexed folder and check whether Android exposes it to Gee Player. Import an SRT file through the Android picker; reopen the video offline and confirm it reloads. In Settings, save your own SubDL key and enable automatic search. Test a video with an exact release match, a title with several matches that needs manual choice, and a title with no match. Verify playback continues while a subtitle downloads and that an invalid key or offline network gives a useful status. These runtime checks are still pending.

## Device check for Phase 6

Favorite media from the library and player, create a playlist, add and remove tracks, and confirm the data survives an app restart. Play part of a video and confirm Home shows it under Continue watching. Test shuffle and each repeat mode with several songs. In a video, test audio-track selection, customized subtitles, double-tap seek, left-side brightness, right-side volume, screen lock, and Picture in Picture. Start music, turn off the screen, and verify the notification, lock-screen, headset, phone-call interruption, and headphone-disconnection controls. These runtime checks are still pending.

## Device check for Phase 7

Change the accent and pure-black theme, restart the app, and confirm both choices persist. Set a non-default playback speed and verify newly opened media starts at that rate. Disable resume playback and confirm saved positions are ignored. Disable video gestures and confirm double-tap, brightness, and volume gestures no longer respond. Finally, disable background audio, hide the app while music is playing, and confirm playback pauses. These runtime checks are still pending.

## Device check for Phase 8

Start a multi-track music queue, open the playing queue, and verify selecting, removing, and reordering upcoming tracks updates both the player and Android media controls without interrupting the current track. Start and cancel a sleep timer, confirm its countdown remains visible after navigating away from the player, and verify playback pauses when the timer expires. These runtime checks are still pending.

## Device check for Phase 9

Download and import several subtitles, open Settings > Storage, and confirm the displayed file count and size increase. Clear the cache, verify the count returns to zero, then confirm the original video, music, and external subtitle files remain on the device. These runtime checks are still pending.

## Quality checks

Run `flutter analyze` and `flutter test` after changes. Tests cover media mapping, search and sorting, permissions, folder navigation, Home previews, foreground refresh, playback source resolution, progress storage, favorites, playlists, history, background media-state publishing, subtitle matching, cache extraction, and SubDL request handling. The development APK builds and runs on Android 15. An unsigned release App Bundle also builds for structural verification; a distributable bundle still requires the owner's upload key.

## API configuration

No API key is needed for local playback or imported subtitles. For online search, create a SubDL key in your own account, open Gee Player Settings, enter the key, and save it. The key is stored with Android secure storage. Keys must not be committed to Git or packaged into the app. A key stored on a client device cannot be completely secret from a determined attacker.

## Builds and platform notes

The Android application ID is `com.gee.player`. The project targets Android only. Release builds never use the Android debug key. Without local upload-key configuration, Gradle can produce an unsigned artifact for verification, but it cannot be distributed through Google Play.

## Release signing

Create the upload keystore interactively so its passwords do not appear in shell history:

```powershell
keytool -genkeypair -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
Copy-Item android/key.properties.example android/key.properties
```

Replace every placeholder in `android/key.properties`, then create the Play Store bundle:

```powershell
flutter build appbundle --release
```

Back up the keystore and passwords securely. Neither `android/key.properties` nor keystore files should be committed to Git.

Before publishing, complete the [Android release checklist](docs/RELEASE_CHECKLIST.md) and host the [privacy notice](PRIVACY.md) at a stable public URL for the store listing.

## Known limitations

- Automatic local subtitle discovery covers embedded tracks, previously imported or downloaded subtitles, and readable indexed subtitle files beside the video. Android's scoped storage does not expose every external subtitle beside a MediaStore video; use the Android file picker to import a hidden file.
- Android MediaStore shows indexed video and audio that the user has granted access to. Android 14 and later can grant access to selected videos only. [Android media access](https://developer.android.com/training/data-storage/shared/media) and [partial video access](https://developer.android.com/about/versions/14/changes/partial-photo-video-access) explain these platform rules. Files outside the indexed collections and subtitle files are not included in this scan.
- Video thumbnails and embedded audio artwork are best effort on Android. Files without readable artwork show a format icon. Native playback and codec support still need device verification; a recognized extension does not guarantee that its codec is playable.
- Android debug compilation, automated tests, and the documented baseline Android 15 emulator checks passed on Windows. Audible output, moving-video codecs, background controls, gestures, Picture-in-Picture behavior, and audio interruptions still need physical-device verification.
