# Android emulator validation

Gee Player was exercised on an Android 15 (API 35) Google APIs x86_64
emulator on September 23, 2026. The debug application was installed as
`com.gee.player` and tested with Android MediaStore content created outside the
app.

## Verified

- The branded Home screen and all six bottom-navigation destinations render
  and expose accessibility labels. The app returns safely after a force-stop
  and relaunch.
- Video access presents the Android 15 choices for limited access, full access,
  and denial. Denial returns to a safe retry state; full access refreshes the
  library.
- Audio access presents the Android permission dialog. Granting access refreshes
  the library and exposes indexed music.
- Empty video and music states render correctly before media is indexed.
- MediaStore refresh discovers externally added WAV and MP4 files and displays
  their title, format, folder, file size, and available duration metadata.
- A five-second WAV opens and starts playback, the player reports an active
  pause control and a two-item queue, and completion advances to the next song.
- The video player route and its playback, audio-track, subtitle, aspect-ratio,
  lock, Picture-in-Picture, and fullscreen controls load without an application
  error for an indexed synthetic MP4.
- Settings > Storage opens the Flutter license page and lists the application
  and dependency license entries.
- No `FATAL EXCEPTION`, app-specific `AndroidRuntime`, or `E/flutter` entry was
  present in the emulator log after these checks.

## Build verification

- `flutter analyze` completed without issues.
- All 50 Flutter tests passed.
- The debug APK built and installed on the emulator.
- `flutter build appbundle --release` produced
  `build/app/outputs/bundle/release/app-release.aab`.
- The release bundle is intentionally unsigned because no owner upload key was
  configured. `jarsigner` confirmed that it is unsigned, and Gradle's signing
  report confirmed that the release variant does not fall back to the debug key.

## Still required before release

The headless emulator ran without audio output, and its screen-recorded MP4 was
not a representative codec sample. Complete the unchecked items in
`RELEASE_CHECKLIST.md` on a physical phone and with representative media. In
particular, verify audible output, moving-video decoding, seek and resume,
Android selected-video access, notifications and lock-screen controls, headset
and audio-focus behavior, rotation, gestures, Picture-in-Picture, subtitles,
cache safety, and owner-signed Play delivery.
