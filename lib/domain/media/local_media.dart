enum MediaKind { video, audio }

class LocalMedia {
  const LocalMedia({
    required this.id,
    required this.kind,
    required this.uri,
    required this.fileName,
    required this.folderPath,
    this.duration,
    this.sizeBytes,
    this.dateAdded,
    this.mimeType,
    this.artist,
  });

  final String id;
  final MediaKind kind;
  final String uri;
  final String fileName;
  final String folderPath;
  final Duration? duration;
  final int? sizeBytes;
  final DateTime? dateAdded;
  final String? mimeType;
  final String? artist;

  String get title {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }

  String get format {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(dot + 1).toUpperCase() : '';
  }
}
