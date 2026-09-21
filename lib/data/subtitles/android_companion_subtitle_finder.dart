import 'package:flutter/services.dart';
import 'package:gee_player/domain/media/local_media.dart';

class CompanionSubtitle {
  const CompanionSubtitle(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

abstract interface class CompanionSubtitleFinder {
  Future<CompanionSubtitle?> find(LocalMedia media, List<String> languages);
}

/// Checks readable, indexed sidecar files in the same MediaStore folder.
/// Android may hide documents here; the user can still import one with SAF.
class AndroidCompanionSubtitleFinder implements CompanionSubtitleFinder {
  const AndroidCompanionSubtitleFinder();

  static const _channel = MethodChannel('com.gee.player/media_library');

  @override
  Future<CompanionSubtitle?> find(
    LocalMedia media,
    List<String> languages,
  ) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'findCompanionSubtitle',
        {
          'folderPath': media.folderPath,
          'fileName': media.fileName,
          'languages': languages,
        },
      );
      final name = result?['name'];
      final bytes = result?['bytes'];
      if (name is! String || bytes is! Uint8List) return null;
      return CompanionSubtitle(name, bytes);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
