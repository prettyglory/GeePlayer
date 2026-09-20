import 'package:gee_player/domain/media/library_snapshot.dart';
import 'package:gee_player/domain/media/local_media.dart';

enum MediaSort { newest, name, duration, size }

abstract final class MediaLibraryQuery {
  static List<LocalMedia> searchAndSort(
    Iterable<LocalMedia> items, {
    required String query,
    required MediaSort sort,
  }) {
    final needle = query.trim().toLowerCase();
    final matches = items.where((item) {
      return needle.isEmpty ||
          item.title.toLowerCase().contains(needle) ||
          item.folderPath.toLowerCase().contains(needle) ||
          (item.artist?.toLowerCase().contains(needle) ?? false);
    }).toList();

    matches.sort((a, b) {
      final primary = switch (sort) {
        MediaSort.newest =>
          (b.dateAdded?.millisecondsSinceEpoch ?? 0).compareTo(
            a.dateAdded?.millisecondsSinceEpoch ?? 0,
          ),
        MediaSort.name => a.title.toLowerCase().compareTo(
          b.title.toLowerCase(),
        ),
        MediaSort.duration => (b.duration?.inMilliseconds ?? 0).compareTo(
          a.duration?.inMilliseconds ?? 0,
        ),
        MediaSort.size => (b.sizeBytes ?? 0).compareTo(a.sizeBytes ?? 0),
      };
      return primary != 0
          ? primary
          : a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return matches;
  }

  static List<MediaFolder> searchFolders(
    Iterable<MediaFolder> folders, {
    required String query,
  }) {
    final needle = query.trim().toLowerCase();
    return folders.where((folder) {
      return needle.isEmpty ||
          folder.name.toLowerCase().contains(needle) ||
          folder.path.toLowerCase().contains(needle);
    }).toList();
  }
}
