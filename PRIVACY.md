# Gee Player Privacy Notice

Effective date: September 23, 2026

Gee Player is a local Android media player. It does not require a Gee Player account and does not include advertising, analytics, telemetry, or crash-reporting services.

## Data stored on the device

Gee Player stores the following information locally so its features work:

- media metadata made available through Android MediaStore;
- playback positions and history;
- favorites, playlists, and playlist order;
- appearance, playback, and subtitle preferences;
- imported or downloaded subtitle copies in app storage; and
- an optional SubDL API key in Android secure storage.

Gee Player does not upload video or audio file contents to a Gee Player server. The project does not operate a backend service.

## Optional SubDL requests

Online subtitle search is disabled by default. If you configure a SubDL API key and use online subtitle features, Gee Player sends the key, a media filename or title, the selected subtitle language, and standard network request information to SubDL. Selected subtitle files are then downloaded from SubDL. Those requests are governed by SubDL's own terms and privacy practices.

## Android permissions

Gee Player requests video or audio access only when needed to discover and play media available to the app. Android may allow you to grant access to selected videos instead of the full video library. Foreground-service and wake-lock permissions support background music playback and media controls.

## Managing local data

You can clear playback history, remove favorites and playlists, reset general settings, remove the SubDL API key, and clear cached subtitle copies from within the app. Clearing the subtitle cache does not delete original media or external subtitle files. Uninstalling Gee Player removes its app-managed local data according to Android's normal uninstall behavior.

## Security

The optional SubDL key is stored through Android secure storage. No client-side application can guarantee complete secrecy against a determined attacker with control of the device, so use a limited personal API key and revoke it through SubDL if necessary.

## Changes and contact

Material changes to this notice should be recorded in this file with a new effective date. Questions or reports can be submitted through the Gee Player GitHub repository issue tracker.
