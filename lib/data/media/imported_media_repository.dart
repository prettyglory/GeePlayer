import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:gee_player/domain/media/library_snapshot.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/domain/media/local_media_repository.dart';
import 'package:path_provider/path_provider.dart';

/// Files chosen on iOS are copied into app support so they remain available
/// after the system's temporary picker copy is removed.
class ImportedMediaRepository implements LocalMediaRepository {
  ImportedMediaRepository({
    Future<Directory> Function()? libraryDirectory,
    Future<List<XFile>> Function()? pickFiles,
  }) : _libraryDirectory = libraryDirectory ?? _defaultLibraryDirectory,
       _pickFiles = pickFiles ?? openFiles;

  final Future<Directory> Function() _libraryDirectory;
  final Future<List<XFile>> Function() _pickFiles;

  static const _videoExtensions = {'mp4', 'mkv', 'avi', 'mov', 'webm', 'm4v'};
  static const _audioExtensions = {
    'mp3',
    'aac',
    'wav',
    'flac',
    'ogg',
    'm4a',
    'opus',
  };

  static Future<Directory> _defaultLibraryDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}${Platform.pathSeparator}ImportedMedia');
  }

  @override
  bool get supportsFileImport => true;

  @override
  Future<LibrarySnapshot> loadLibrary() async {
    final directory = await _libraryDirectory();
    if (!await directory.exists()) {
      return const LibrarySnapshot(
        items: [],
        access: MediaAccess(
          videos: MediaAccessLevel.notRequired,
          audio: MediaAccessLevel.notRequired,
        ),
      );
    }

    final items = <LocalMedia>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final kind = _kindFor(name);
      if (kind == null) continue;
      try {
        final stat = await entity.stat();
        items.add(
          LocalMedia(
            id: entity.uri.toString(),
            kind: kind,
            uri: entity.uri.toString(),
            fileName: name,
            folderPath: 'Imported media',
            sizeBytes: stat.size,
            dateAdded: stat.modified,
          ),
        );
      } on FileSystemException {
        // A file can disappear while the library is being read.
      }
    }
    items.sort((a, b) {
      final aDate = a.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return LibrarySnapshot(
      items: items,
      access: const MediaAccess(
        videos: MediaAccessLevel.notRequired,
        audio: MediaAccessLevel.notRequired,
      ),
    );
  }

  @override
  Future<MediaAccess> requestAccess({MediaKind? kind}) async =>
      const MediaAccess(
        videos: MediaAccessLevel.notRequired,
        audio: MediaAccessLevel.notRequired,
      );

  @override
  Future<int> importFiles() async {
    final selected = await _pickFiles();
    if (selected.isEmpty) return 0;

    final directory = await _libraryDirectory();
    await directory.create(recursive: true);
    var imported = 0;
    for (final selectedFile in selected) {
      final name = selectedFile.name.split(RegExp(r'[/\\]')).last;
      if (_kindFor(name) == null) continue;

      var destination = File('${directory.path}${Platform.pathSeparator}$name');
      var duplicate = 2;
      final dot = name.lastIndexOf('.');
      final stem = name.substring(0, dot);
      final extension = name.substring(dot);
      while (await destination.exists()) {
        destination = File(
          '${directory.path}${Platform.pathSeparator}$stem ($duplicate)$extension',
        );
        duplicate++;
      }

      final partial = File('${destination.path}.partial');
      try {
        await selectedFile.saveTo(partial.path);
        await partial.rename(destination.path);
        imported++;
      } catch (_) {
        if (await partial.exists()) await partial.delete();
        rethrow;
      }
    }
    return imported;
  }

  @override
  Future<void> openAppSettings() async {}

  static MediaKind? _kindFor(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0) return null;
    final extension = name.substring(dot + 1).toLowerCase();
    if (_videoExtensions.contains(extension)) return MediaKind.video;
    if (_audioExtensions.contains(extension)) return MediaKind.audio;
    return null;
  }

  @override
  Future<Uint8List?> loadArtwork(LocalMedia media) async => null;
}
