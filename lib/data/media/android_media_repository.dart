import 'package:flutter/services.dart';
import 'package:gee_player/domain/media/library_snapshot.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/domain/media/local_media_repository.dart';

class AndroidMediaRepository implements LocalMediaRepository {
  AndroidMediaRepository({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.gee.player/media_library');

  final MethodChannel _channel;
  final Map<String, Future<Uint8List?>> _artworkCache = {};

  @override
  Future<LibrarySnapshot> loadLibrary() async {
    final response = await _channel.invokeMapMethod<String, dynamic>('scan');
    if (response == null) throw const FormatException('No media scan result.');

    final rawItems = response['items'];
    if (rawItems is! List) {
      throw const FormatException('Invalid media scan result.');
    }

    return LibrarySnapshot(
      access: _accessFrom(response),
      items: [
        for (final rawItem in rawItems)
          _itemFrom(Map<String, dynamic>.from(rawItem as Map)),
      ],
    );
  }

  @override
  Future<MediaAccess> requestAccess({MediaKind? kind}) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'requestAccess',
      {'kind': kind?.name ?? 'both'},
    );
    if (response == null) throw const FormatException('No permission result.');
    return _accessFrom(response);
  }

  @override
  Future<void> openAppSettings() => _channel.invokeMethod<void>('openSettings');

  @override
  Future<Uint8List?> loadArtwork(LocalMedia media) {
    final existing = _artworkCache[media.uri];
    if (existing != null) return existing;
    if (_artworkCache.length >= 128) {
      _artworkCache.remove(_artworkCache.keys.first);
    }
    final result = _channel
        .invokeMethod<Uint8List>('artwork', {
          'uri': media.uri,
          'kind': media.kind.name,
        })
        .catchError((Object error) => null);
    _artworkCache[media.uri] = result;
    return result;
  }

  MediaAccess _accessFrom(Map<String, dynamic> response) => MediaAccess(
    videos: _levelFrom(response['videoAccess']),
    audio: _levelFrom(response['audioAccess']),
  );

  MediaAccessLevel _levelFrom(Object? value) => switch (value) {
    'granted' => MediaAccessLevel.granted,
    'limited' => MediaAccessLevel.limited,
    'denied' => MediaAccessLevel.denied,
    _ => throw FormatException('Unknown media access level: $value'),
  };

  LocalMedia _itemFrom(Map<String, dynamic> item) {
    final kind = switch (item['kind']) {
      'video' => MediaKind.video,
      'audio' => MediaKind.audio,
      _ => throw FormatException('Unknown media kind: ${item['kind']}'),
    };
    final durationMs = item['durationMs'] as int?;
    final dateAddedMs = item['dateAddedMs'] as int?;

    return LocalMedia(
      id: item['id'] as String,
      kind: kind,
      uri: item['uri'] as String,
      fileName: item['fileName'] as String,
      folderPath: item['folderPath'] as String? ?? 'Unknown folder',
      duration: durationMs == null ? null : Duration(milliseconds: durationMs),
      sizeBytes: item['sizeBytes'] as int?,
      dateAdded: dateAddedMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dateAddedMs),
      mimeType: item['mimeType'] as String?,
      artist: item['artist'] as String?,
    );
  }
}
