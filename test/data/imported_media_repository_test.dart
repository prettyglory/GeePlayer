import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/data/media/imported_media_repository.dart';

void main() {
  test(
    'imports selected media persistently and keeps duplicate names',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'gee-player-media-test-',
      );
      addTearDown(() => root.delete(recursive: true));
      final source = File('${root.path}${Platform.pathSeparator}Movie.mp4');
      await source.writeAsBytes([1, 2, 3, 4]);
      final importDirectory = Directory(
        '${root.path}${Platform.pathSeparator}ImportedMedia',
      );
      final repository = ImportedMediaRepository(
        libraryDirectory: () async => importDirectory,
        pickFiles: () async => [XFile(source.path)],
      );

      expect((await repository.loadLibrary()).items, isEmpty);
      expect(await repository.importFiles(), 1);
      expect(await repository.importFiles(), 1);

      final snapshot = await repository.loadLibrary();
      expect(snapshot.videos.map((item) => item.fileName).toSet(), {
        'Movie.mp4',
        'Movie (2).mp4',
      });
      expect(snapshot.folders.single.name, 'Imported media');
      expect(snapshot.videos.first.sizeBytes, 4);
    },
  );

  test('skips unsupported selections without adding a library entry', () async {
    final root = await Directory.systemTemp.createTemp(
      'gee-player-media-test-',
    );
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}${Platform.pathSeparator}notes.txt');
    await source.writeAsString('notes');
    final repository = ImportedMediaRepository(
      libraryDirectory: () async => root,
      pickFiles: () async => [XFile(source.path)],
    );

    expect(await repository.importFiles(), 0);
    expect((await repository.loadLibrary()).items, isEmpty);
  });
}
