import 'package:gee_player/domain/media/local_media.dart';

enum MediaAccessLevel { granted, limited, denied, notRequired, unsupported }

class MediaAccess {
  const MediaAccess({required this.videos, required this.audio});

  final MediaAccessLevel videos;
  final MediaAccessLevel audio;

  bool get canReadVideos =>
      videos == MediaAccessLevel.granted ||
      videos == MediaAccessLevel.limited ||
      videos == MediaAccessLevel.notRequired;

  bool get canReadAudio =>
      audio == MediaAccessLevel.granted ||
      audio == MediaAccessLevel.notRequired;
}

class MediaFolder {
  const MediaFolder({required this.path, required this.items});

  final String path;
  final List<LocalMedia> items;

  String get name {
    final normalized = path
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+$'), '');
    final slash = normalized.lastIndexOf('/');
    return slash >= 0 ? normalized.substring(slash + 1) : normalized;
  }
}

class LibrarySnapshot {
  const LibrarySnapshot({required this.items, required this.access});

  final List<LocalMedia> items;
  final MediaAccess access;

  List<LocalMedia> get videos =>
      items.where((item) => item.kind == MediaKind.video).toList();

  List<LocalMedia> get music =>
      items.where((item) => item.kind == MediaKind.audio).toList();

  List<MediaFolder> get folders {
    final grouped = <String, List<LocalMedia>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.folderPath, () => []).add(item);
    }
    final folders = [
      for (final entry in grouped.entries)
        MediaFolder(path: entry.key, items: entry.value),
    ];
    folders.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return folders;
  }
}
