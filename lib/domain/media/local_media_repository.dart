import 'package:gee_player/domain/media/library_snapshot.dart';

abstract interface class LocalMediaRepository {
  bool get supportsFileImport;

  Future<LibrarySnapshot> loadLibrary();

  Future<MediaAccess> requestAccess();

  Future<int> importFiles();
}
