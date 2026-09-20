import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gee_player/data/media/android_media_repository.dart';
import 'package:gee_player/data/media/imported_media_repository.dart';
import 'package:gee_player/domain/media/library_snapshot.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/domain/media/local_media_repository.dart';

final localMediaRepositoryProvider = Provider<LocalMediaRepository>((ref) {
  if (kIsWeb) return const _UnsupportedMediaRepository();
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => AndroidMediaRepository(),
    TargetPlatform.iOS => ImportedMediaRepository(),
    _ => const _UnsupportedMediaRepository(),
  };
});

final mediaLibraryProvider =
    AsyncNotifierProvider<MediaLibraryController, LibrarySnapshot>(
      MediaLibraryController.new,
      retry: (retryCount, error) => null,
    );

class MediaLibraryController extends AsyncNotifier<LibrarySnapshot> {
  @override
  Future<LibrarySnapshot> build() =>
      ref.watch(localMediaRepositoryProvider).loadLibrary();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(localMediaRepositoryProvider).loadLibrary(),
    );
  }

  Future<void> requestAccess({MediaKind? kind}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(localMediaRepositoryProvider);
      await repository.requestAccess(kind: kind);
      return repository.loadLibrary();
    });
  }

  Future<int?> importFiles() async {
    int? imported;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(localMediaRepositoryProvider);
      imported = await repository.importFiles();
      return repository.loadLibrary();
    });
    return state.hasError ? null : imported;
  }
}

class _UnsupportedMediaRepository implements LocalMediaRepository {
  const _UnsupportedMediaRepository();

  static const _access = MediaAccess(
    videos: MediaAccessLevel.unsupported,
    audio: MediaAccessLevel.unsupported,
  );

  @override
  bool get supportsFileImport => false;

  @override
  Future<LibrarySnapshot> loadLibrary() async =>
      const LibrarySnapshot(items: [], access: _access);

  @override
  Future<MediaAccess> requestAccess({MediaKind? kind}) async => _access;

  @override
  Future<int> importFiles() =>
      throw UnsupportedError('Media import is available on iOS.');

  @override
  Future<Uint8List?> loadArtwork(LocalMedia media) async => null;
}
