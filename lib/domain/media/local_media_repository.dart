import 'package:gee_player/domain/media/library_snapshot.dart';
import 'package:gee_player/domain/media/local_media.dart';

abstract interface class LocalMediaRepository {
  bool get supportsFileImport;

  Future<LibrarySnapshot> loadLibrary();

  Future<MediaAccess> requestAccess({MediaKind? kind});

  Future<int> importFiles();
}
