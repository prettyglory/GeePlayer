import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/data/subtitles/subdl_provider.dart';
import 'package:gee_player/domain/subtitles/subtitle_candidate.dart';

class RecordingAdapter implements HttpClientAdapter {
  RecordingAdapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'search uses documented SubDL parameters and parses unpacked files',
    () async {
      final adapter = RecordingAdapter(
        (_) => ResponseBody.fromString(
          '''
      {"status":true,"subtitles":[{"name":"Season.zip","release_name":"Show.S01E02","language":"SW","url":"/subtitle/pack.zip","unpack_files":[{"name":"Show.S01E02.srt","release_name":"Show.S01E02","language":"SW","season":1,"episode":2,"url":"/subtitle/pack/file2"}]}]}
      ''',
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );
      final client = Dio()..httpClientAdapter = adapter;
      final provider = SubdlProvider(client);
      final result = await provider.searchByFileName(
        'Show.S01E02.mkv',
        apiKey: 'private-key',
        languages: ['SW', 'EN'],
      );
      expect(adapter.lastRequest!.uri.host, 'api.subdl.com');
      expect(adapter.lastRequest!.uri.path, '/api/v1/subtitles');
      expect(
        adapter.lastRequest!.queryParameters['file_name'],
        'Show.S01E02.mkv',
      );
      expect(adapter.lastRequest!.queryParameters['languages'], 'SW,EN');
      expect(adapter.lastRequest!.queryParameters['unpack'], 1);
      expect(result, hasLength(1));
      expect(result.single.language, 'SW');
      expect(result.single.downloadPath, '/subtitle/pack/file2');
      expect(result.single.episode, 2);
    },
  );

  test(
    'downloads from the documented host without putting the key in the URL',
    () async {
      final adapter = RecordingAdapter(
        (_) => ResponseBody.fromBytes(
          [1, 2, 3],
          200,
          headers: {
            Headers.contentLengthHeader: ['3'],
          },
        ),
      );
      final provider = SubdlProvider(Dio()..httpClientAdapter = adapter);
      const candidate = SubtitleCandidate(
        name: 'Movie.srt',
        releaseName: 'Movie',
        language: 'EN',
        downloadPath: '/subtitle/123/file',
      );
      final progress = <int>[];
      expect(
        await provider.download(
          candidate,
          apiKey: 'private-key',
          onProgress: (n, _) => progress.add(n),
        ),
        [1, 2, 3],
      );
      expect(adapter.lastRequest!.uri.host, 'dl.subdl.com');
      expect(adapter.lastRequest!.uri.query, isEmpty);
      expect(progress.last, 3);
    },
  );

  test('rate limits return a safe message without exposing the key', () async {
    final adapter = RecordingAdapter(
      (_) => ResponseBody.fromString('rate limited', 429),
    );
    final provider = SubdlProvider(Dio()..httpClientAdapter = adapter);
    await expectLater(
      provider.searchByTitle('Movie', apiKey: 'private-key', languages: ['EN']),
      throwsA(
        isA<SubtitleProviderException>().having(
          (e) => e.message,
          'message',
          allOf(contains('rate limit'), isNot(contains('private-key'))),
        ),
      ),
    );
  });
}
