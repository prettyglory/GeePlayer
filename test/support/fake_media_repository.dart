import 'dart:typed_data';

import 'package:gee_player/domain/media/library_snapshot.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/domain/media/local_media_repository.dart';

class FakeMediaRepository implements LocalMediaRepository {
  FakeMediaRepository({required this.snapshot, this.canImport = false});

  LibrarySnapshot snapshot;
  final bool canImport;
  MediaKind? requestedKind;
  int loadCount = 0;

  @override
  bool get supportsFileImport => canImport;

  @override
  Future<LibrarySnapshot> loadLibrary() async {
    loadCount++;
    return snapshot;
  }

  @override
  Future<MediaAccess> requestAccess({MediaKind? kind}) async {
    requestedKind = kind;
    return snapshot.access;
  }

  @override
  Future<int> importFiles() async => 0;

  @override
  Future<Uint8List?> loadArtwork(LocalMedia media) async => null;
}

LibrarySnapshot emptyAccessibleLibrary() => const LibrarySnapshot(
  items: [],
  access: MediaAccess(
    videos: MediaAccessLevel.granted,
    audio: MediaAccessLevel.granted,
  ),
);
