import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:gee_player/app/playback_controller.dart';
import 'package:gee_player/data/subtitles/subdl_provider.dart';
import 'package:gee_player/data/subtitles/subtitle_preferences.dart';
import 'package:gee_player/data/subtitles/subtitle_store.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/domain/subtitles/subtitle_candidate.dart';
import 'package:gee_player/domain/subtitles/subtitle_matcher.dart';
import 'package:media_kit/media_kit.dart';

class SubtitleController extends ChangeNotifier {
  SubtitleController(
    this._playback,
    this._store,
    this._preferences,
    this._provider,
  ) {
    _playback.addListener(_onPlaybackChanged);
    _onPlaybackChanged();
  }

  final PlaybackController _playback;
  final SubtitleStore _store;
  final SubtitlePreferences _preferences;
  final SubtitleProvider _provider;
  StreamSubscription<Tracks>? _tracksSubscription;
  int _session = -1;
  bool _disposed = false;
  bool busy = false;
  double? progress;
  String? message;
  List<StoredSubtitle> cached = const [];
  List<SubtitleCandidate> online = const [];
  List<SubtitleTrack> embedded = const [];

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _onPlaybackChanged() {
    final media = _playback.current;
    if (media == null || media.kind != MediaKind.video) {
      if (_session != -1) {
        _session = -1;
        cached = const [];
        online = const [];
        embedded = const [];
        message = null;
        _notify();
      }
      return;
    }
    if (_playback.loading ||
        _playback.error != null ||
        _playback.sessionRevision == _session) {
      return;
    }
    _session = _playback.sessionRevision;
    _tracksSubscription ??= _playback.player.stream.tracks.listen(
      (_) => _refreshEmbedded(),
    );
    _refreshEmbedded();
    unawaited(_loadForSession(media, _session));
  }

  void _refreshEmbedded() {
    embedded = _playback.player.state.tracks.subtitle
        .where((track) => track.id != 'auto' && track.id != 'no' && !track.uri)
        .toList();
    _notify();
  }

  bool _current(LocalMedia media, int session) =>
      !_disposed &&
      _session == session &&
      _playback.current?.id == media.id &&
      !_playback.loading;

  Future<void> _loadForSession(LocalMedia media, int session) async {
    busy = true;
    progress = null;
    online = const [];
    message = 'Checking subtitles…';
    _notify();
    try {
      final order = await _preferences.languageOrder();
      final files = await _store.cachedFor(media.id);
      if (!_current(media, session)) return;
      cached = files;
      final embeddedChoice = _preferredEmbedded(order);
      if (embeddedChoice != null) {
        await _playback.player.setSubtitleTrack(embeddedChoice);
        message = 'Embedded subtitles';
        return;
      }
      final local = _preferredCached(order);
      if (local != null) {
        await _applyFile(local);
        message = '${local.source} subtitle';
        return;
      }
      if (!await _preferences.autoSearch()) {
        message = 'No local subtitle. Search online or import a file.';
        return;
      }
      final key = await _preferences.apiKey();
      if (key == null || key.isEmpty) {
        message = 'Add a SubDL API key in Settings to search automatically.';
        return;
      }
      if (await _store.isNegativeCached(media.id, order.first)) {
        message = 'No recent SubDL match. You can search manually.';
        return;
      }
      final results = await _provider.searchByFileName(
        media.fileName,
        apiKey: key,
        languages: order,
      );
      if (!_current(media, session)) return;
      online = results;
      if (results.isEmpty) {
        await _store.recordNegative(media.id, order.first);
        message = 'No SubDL subtitle found. Try searching by title.';
        return;
      }
      final match = SubtitleMatcher.confidentMatch(
        media.fileName,
        results,
        order,
      );
      if (match == null) {
        message = 'Choose a subtitle from the search results.';
        return;
      }
      await _downloadAndApply(media, match, key, session);
    } catch (error) {
      if (_current(media, session)) message = _errorText(error);
    } finally {
      if (_current(media, session)) {
        busy = false;
        progress = null;
        _notify();
      }
    }
  }

  SubtitleTrack? _preferredEmbedded(List<String> order) {
    for (final code in order) {
      for (final track in embedded) {
        if (_trackLanguage(track.language) == code) return track;
      }
    }
    return embedded.length == 1 ? embedded.first : null;
  }

  StoredSubtitle? _preferredCached(List<String> order) {
    for (final file in cached) {
      if (file.source == 'Imported') return file;
    }
    for (final code in order) {
      for (final file in cached) {
        if (file.language == code) return file;
      }
    }
    return null;
  }

  static String? _trackLanguage(String? value) =>
      switch (value?.toLowerCase()) {
        'sw' || 'swa' || 'swahili' => 'SW',
        'en' || 'eng' || 'english' => 'EN',
        _ => null,
      };

  Future<void> selectEmbedded(SubtitleTrack track) async {
    await _playback.player.setSubtitleTrack(track);
    message = 'Embedded subtitle selected';
    _notify();
  }

  Future<void> selectCached(StoredSubtitle file) async {
    await _applyFile(file);
    message = '${file.source} subtitle selected';
    _notify();
  }

  Future<void> disable() async {
    await _playback.player.setSubtitleTrack(SubtitleTrack.no());
    message = 'Subtitles off';
    _notify();
  }

  Future<void> _applyFile(StoredSubtitle file) =>
      _playback.player.setSubtitleTrack(
        SubtitleTrack.uri(
          file.file.uri.toString(),
          title: file.source,
          language: file.language.toLowerCase(),
        ),
      );

  Future<void> importLocal() async {
    final media = _playback.current;
    if (media == null || media.kind != MediaKind.video) return;
    const types = XTypeGroup(
      label: 'Subtitles',
      extensions: ['srt', 'vtt', 'ass', 'ssa', 'sub'],
    );
    try {
      final selected = await openFile(acceptedTypeGroups: [types]);
      if (selected == null || _playback.current?.id != media.id) return;
      final file = await _store.importFile(media.id, selected);
      cached = await _store.cachedFor(media.id);
      await _applyFile(file);
      message = 'Imported ${selected.name}';
    } catch (error) {
      message = _errorText(error);
    }
    _notify();
  }

  Future<void> search(String title) async {
    final media = _playback.current;
    if (media == null || media.kind != MediaKind.video || busy) return;
    final query = title.trim();
    if (query.length < 2) {
      message = 'Enter at least two letters.';
      _notify();
      return;
    }
    final session = _session;
    busy = true;
    message = 'Searching SubDL…';
    _notify();
    try {
      final key = await _preferences.apiKey();
      if (key == null || key.isEmpty) {
        throw const SubtitleProviderException(
          'Add your SubDL API key in Settings.',
        );
      }
      final results = await _provider.searchByTitle(
        query,
        apiKey: key,
        languages: await _preferences.languageOrder(),
      );
      if (!_current(media, session)) return;
      online = results;
      message = results.isEmpty
          ? 'No subtitles found for that title.'
          : '${results.length} subtitle options';
    } catch (error) {
      if (_current(media, session)) message = _errorText(error);
    } finally {
      if (_current(media, session)) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> download(SubtitleCandidate candidate) async {
    final media = _playback.current;
    if (media == null || media.kind != MediaKind.video || busy) return;
    final session = _session;
    busy = true;
    progress = null;
    message = 'Downloading subtitle…';
    _notify();
    try {
      final key = await _preferences.apiKey();
      if (key == null || key.isEmpty) {
        throw const SubtitleProviderException(
          'Add your SubDL API key in Settings.',
        );
      }
      await _downloadAndApply(media, candidate, key, session);
    } catch (error) {
      if (_current(media, session)) message = _errorText(error);
    } finally {
      if (_current(media, session)) {
        busy = false;
        progress = null;
        _notify();
      }
    }
  }

  Future<void> _downloadAndApply(
    LocalMedia media,
    SubtitleCandidate candidate,
    String key,
    int session,
  ) async {
    final bytes = await _provider.download(
      candidate,
      apiKey: key,
      onProgress: (received, total) {
        if (_current(media, session)) {
          progress = total > 0 ? received / total : null;
          _notify();
        }
      },
    );
    if (!_current(media, session)) return;
    final file = await _store.saveDownload(
      media.id,
      media.fileName,
      candidate,
      bytes,
    );
    if (!_current(media, session)) return;
    cached = await _store.cachedFor(media.id);
    await _store.clearNegative(
      media.id,
      (await _preferences.languageOrder()).first,
    );
    await _applyFile(file);
    message = '${candidate.language} subtitle ready';
  }

  static String _errorText(Object error) => error is SubtitleProviderException
      ? error.message
      : 'Could not load subtitle. Try another file or search result.';

  @override
  void dispose() {
    _disposed = true;
    _playback.removeListener(_onPlaybackChanged);
    unawaited(_tracksSubscription?.cancel());
    super.dispose();
  }
}
