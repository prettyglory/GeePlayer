import 'dart:typed_data';

import 'package:gee_player/domain/media/library_snapshot.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/domain/media/local_media_repository.dart';

class FakeMediaRepository implements LocalMediaRepository {
  FakeMediaRepository({required this.snapshot});

  LibrarySnapshot snapshot;
  MediaKind? requestedKind;
  int loadCount = 0;
  int openSettingsCount = 0;

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
  Future<void> openAppSettings() async {
    openSettingsCount++;
  }

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
