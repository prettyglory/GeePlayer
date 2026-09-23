# Gee Player Android release checklist

## Automated gates

- [x] `flutter analyze` reports no issues.
- [x] `flutter test` passes the complete suite.
- [x] `flutter build apk --debug` succeeds.
- [ ] `flutter build appbundle --release` succeeds with the owner upload key.
- [ ] `jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab` reports a valid non-debug signer.

## Signing and versioning

- [ ] Generate the owner upload keystore interactively using the command in the README.
- [ ] Copy `android/key.properties.example` to ignored `android/key.properties` and replace every placeholder.
- [ ] Back up the keystore and passwords in two secure locations.
- [ ] Enroll in Google Play App Signing before the first production upload.
- [ ] Increase both the semantic version and build number in `pubspec.yaml` for every store release.
- [ ] Confirm the permanent application ID is `com.gee.player` before publishing.

## Android runtime verification

- [ ] Verify separate video and audio permission flows, including denial and Android 14+ selected-video access.
- [ ] Test library discovery, search, sort, folders, artwork, and pull-to-refresh with real media.
- [ ] Test supported and unsupported video/audio codecs on at least one physical phone.
- [ ] Verify seek, playback speed, resume, queue editing, shuffle, repeat, and sleep timer behavior.
- [ ] Verify embedded, imported, companion, and SubDL subtitles, including offline and invalid-key behavior.
- [ ] Verify notification, lock-screen, headset, audio-focus, interruption, and unplug controls.
- [ ] Verify fullscreen rotation, Picture-in-Picture, screen lock, brightness, volume, and double-tap gestures.
- [ ] Confirm app data persists across process death and restart.
- [ ] Confirm subtitle cache clearing never removes original media or external subtitles.

## Distribution and compliance

- [ ] Review the in-app open-source license list and native media-library notices against the exact release dependencies.
- [ ] Host `PRIVACY.md` at a stable public URL and add that URL to the store listing.
- [ ] Complete Google Play Data safety and content-rating forms from the actual release behavior.
- [ ] Prepare phone screenshots, feature graphic, icon, short description, and full description.
- [ ] Upload first to an internal testing track and review automated pre-launch reports.
- [ ] Install the Play-delivered build from the internal track and repeat the critical playback checks.

## Current local verification

The repository is configured so a release variant never falls back to the Android debug key. With no `android/key.properties`, Gradle's signing report shows the release signing configuration as `null`. An unsigned release App Bundle can be built for structural verification, but it must not be uploaded as the production artifact.

The completed Android 15 checks and their physical-device limitations are recorded in [EMULATOR_VALIDATION.md](EMULATOR_VALIDATION.md).
