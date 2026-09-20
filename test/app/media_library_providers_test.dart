import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/app/media_library_providers.dart';
import 'package:gee_player/domain/media/library_snapshot.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/domain/media/local_media_repository.dart';

void main() {
  test('library controller refreshes after a scoped access request', () async {
    final repository = _FakeMediaRepository();
    final container = ProviderContainer.test(
      overrides: [
        localMediaRepositoryProvider.overrideWith((ref) => repository),
      ],
    );

    expect((await container.read(mediaLibraryProvider.future)).videos, isEmpty);
    await container
        .read(mediaLibraryProvider.notifier)
        .requestAccess(kind: MediaKind.video);

    expect(repository.requestedKind, MediaKind.video);
    expect(
      container.read(mediaLibraryProvider).requireValue.videos.single.title,
      'Clip',
    );
  });
}

class _FakeMediaRepository implements LocalMediaRepository {
  MediaKind? requestedKind;

  @override
  bool get supportsFileImport => false;

  @override
  Future<LibrarySnapshot> loadLibrary() async => LibrarySnapshot(
    items: requestedKind == null
        ? []
        : const [
            LocalMedia(
              id: 'video:1',
              kind: MediaKind.video,
              uri: 'content://video/1',
              fileName: 'Clip.mp4',
              folderPath: 'Movies',
            ),
          ],
    access: const MediaAccess(
      videos: MediaAccessLevel.granted,
      audio: MediaAccessLevel.denied,
    ),
  );

  @override
  Future<MediaAccess> requestAccess({MediaKind? kind}) async {
    requestedKind = kind;
    return const MediaAccess(
      videos: MediaAccessLevel.granted,
      audio: MediaAccessLevel.denied,
    );
  }

  @override
  Future<int> importFiles() => throw UnimplementedError();
}
