import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/data/subtitles/subdl_provider.dart';
import 'package:gee_player/data/subtitles/subtitle_store.dart';
import 'package:gee_player/domain/subtitles/subtitle_candidate.dart';

void main() {
  late Directory root;
  late SubtitleStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('gee_subtitles_');
    store = SubtitleStore(root: root);
  });

  tearDown(() async => root.delete(recursive: true));

  test('extracts a matching episode and caches it for the media id', () async {
    final archive = Archive()
      ..addFile(ArchiveFile.string('Show.S01E01.srt', 'wrong'))
      ..addFile(ArchiveFile.string('Show.S01E02.srt', 'right'));
    const candidate = SubtitleCandidate(
      name: 'Show.Season1.zip',
      releaseName: 'Show.S01E02',
      language: 'SW',
      downloadPath: '/subtitle/season.zip',
    );
    final saved = await store.saveDownload(
      'video:42',
      'Show.S01E02.mkv',
      candidate,
      ZipEncoder().encodeBytes(archive),
    );
    expect(await saved.file.readAsString(), 'right');
    final cached = await store.cachedFor('video:42');
    expect(cached, hasLength(1));
    expect(cached.single.language, 'SW');
    expect(await store.cachedFor('video:43'), isEmpty);
  });

  test('does not extract unsupported files from an archive', () async {
    final archive = Archive()
      ..addFile(ArchiveFile.string('../payload.exe', 'unsafe'));
    const candidate = SubtitleCandidate(
      name: 'pack.zip',
      releaseName: 'Movie',
      language: 'EN',
      downloadPath: '/subtitle/pack.zip',
    );
    await expectLater(
      store.saveDownload(
        'video:1',
        'Movie.mkv',
        candidate,
        ZipEncoder().encodeBytes(archive),
      ),
      throwsA(isA<SubtitleProviderException>()),
    );
    expect(await store.cachedFor('video:1'), isEmpty);
  });

  test('stores a raw subtitle without affecting another media id', () async {
    const candidate = SubtitleCandidate(
      name: 'Movie.srt',
      releaseName: 'Movie',
      language: 'EN',
      downloadPath: '/subtitle/raw-file',
    );
    await store.saveDownload(
      'video:1',
      'Movie.mkv',
      candidate,
      utf8.encode('subtitle text'),
    );
    expect(await store.cachedFor('video:1'), hasLength(1));
    expect(await store.cachedFor('video:2'), isEmpty);
  });

  test('stores a discovered local sidecar for offline playback', () async {
    final saved = await store.saveCompanion(
      'video:1',
      'Movie.sw.srt',
      utf8.encode('local text'),
    );
    expect(await saved.file.readAsString(), 'local text');
    final cached = await store.cachedFor('video:1');
    expect(cached.single.source, 'Local');
  });

  test('measures and clears only app-cached subtitle files', () async {
    const candidate = SubtitleCandidate(
      name: 'Movie.srt',
      releaseName: 'Movie',
      language: 'EN',
      downloadPath: '/subtitle/raw-file',
    );
    await store.saveDownload(
      'video:1',
      'Movie.mkv',
      candidate,
      utf8.encode('downloaded subtitle'),
    );
    await store.saveCompanion(
      'video:2',
      'Other.srt',
      utf8.encode('local subtitle'),
    );
    final unrelated = File('${root.path}${Platform.pathSeparator}keep.txt');
    await unrelated.writeAsString('keep');

    final before = await store.cacheInfo();
    expect(before.fileCount, 2);
    expect(before.totalBytes, greaterThan(0));

    await store.clearCache();

    expect((await store.cacheInfo()).isEmpty, isTrue);
    expect(await unrelated.readAsString(), 'keep');
  });
}
