import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:gee_player/domain/subtitles/subtitle_candidate.dart';

class SubtitleProviderException implements Exception {
  const SubtitleProviderException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// SubDL v1 search/download contract: https://subdl.com/api-doc
class SubdlProvider implements SubtitleProvider {
  SubdlProvider([Dio? client])
    : _client =
          client ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  final Dio _client;
  static const maxDownloadBytes = 8 * 1024 * 1024;

  @override
  Future<List<SubtitleCandidate>> searchByFileName(
    String fileName, {
    required String apiKey,
    required List<String> languages,
  }) => _search({'file_name': fileName}, apiKey, languages);

  @override
  Future<List<SubtitleCandidate>> searchByTitle(
    String title, {
    required String apiKey,
    required List<String> languages,
  }) => _search({'film_name': title}, apiKey, languages);

  Future<List<SubtitleCandidate>> _search(
    Map<String, String> term,
    String apiKey,
    List<String> languages,
  ) async {
    if (apiKey.trim().isEmpty) {
      throw const SubtitleProviderException(
        'Add your SubDL API key in Settings.',
      );
    }
    try {
      final response = await _client.get<Map<String, dynamic>>(
        'https://api.subdl.com/api/v1/subtitles',
        queryParameters: {
          'api_key': apiKey.trim(),
          ...term,
          'languages': languages.join(','),
          'subs_per_page': 30,
          'unpack': 1,
          'client': 'custom_integration',
        },
      );
      final body = response.data;
      if (body == null) {
        throw const SubtitleProviderException(
          'SubDL returned an empty response.',
        );
      }
      if (body['status'] != true) {
        throw SubtitleProviderException(_safeMessage(body['error']));
      }
      final rows = body['subtitles'];
      if (rows is! List) return const [];
      final candidates = <SubtitleCandidate>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final parent = Map<String, dynamic>.from(row);
        final unpacked = parent['unpack_files'];
        if (unpacked is List && unpacked.isNotEmpty) {
          for (final item in unpacked) {
            if (item is Map) {
              final candidate = _parseCandidate(
                Map<String, dynamic>.from(item),
                parent,
              );
              if (candidate != null) candidates.add(candidate);
            }
          }
        } else {
          final candidate = _parseCandidate(parent, parent);
          if (candidate != null) candidates.add(candidate);
        }
      }
      return candidates;
    } on DioException catch (error) {
      throw SubtitleProviderException(_networkMessage(error));
    }
  }

  SubtitleCandidate? _parseCandidate(
    Map<String, dynamic> row,
    Map<String, dynamic> parent,
  ) {
    final path = row['url'];
    if (path is! String || !_validDownloadPath(path)) return null;
    final name = (row['name'] ?? parent['name'] ?? '').toString();
    final release = (row['release_name'] ?? parent['release_name'] ?? name)
        .toString();
    final language = _languageCode(
      (row['language'] ?? row['lang'] ?? parent['language'] ?? parent['lang'])
          ?.toString(),
    );
    if (language == null) return null;
    return SubtitleCandidate(
      name: name,
      releaseName: release,
      language: language,
      downloadPath: path,
      season: _number(row['season'] ?? parent['season']),
      episode: _number(row['episode'] ?? parent['episode']),
    );
  }

  static int? _number(Object? value) =>
      value is int ? value : int.tryParse('$value');

  static String? _languageCode(String? value) {
    if (value == null) return null;
    return switch (value.toLowerCase()) {
      'en' || 'eng' || 'english' => 'EN',
      'sw' || 'swa' || 'swahili' || 'kiswahili' => 'SW',
      _ => null,
    };
  }

  static bool _validDownloadPath(String path) =>
      path.startsWith('/subtitle/') &&
      !path.contains('..') &&
      !path.contains('?') &&
      !path.contains('#');

  @override
  Future<List<int>> download(
    SubtitleCandidate candidate, {
    required String apiKey,
    void Function(int received, int total)? onProgress,
  }) async {
    if (!_validDownloadPath(candidate.downloadPath)) {
      throw const SubtitleProviderException('Invalid subtitle download link.');
    }
    try {
      // SubDL documents anonymous downloads for free keys. Paid accounts can
      // opt into authenticated quota separately; never put a key in a URL here.
      final response = await _client.get<ResponseBody>(
        'https://dl.subdl.com${candidate.downloadPath}',
        options: Options(responseType: ResponseType.stream),
      );
      final body = response.data;
      if (body == null) {
        throw const SubtitleProviderException('Subtitle download was empty.');
      }
      final total =
          int.tryParse(
            response.headers.value(Headers.contentLengthHeader) ?? '',
          ) ??
          -1;
      if (total > maxDownloadBytes) {
        throw const SubtitleProviderException('Subtitle archive is too large.');
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in body.stream) {
        bytes.add(chunk);
        if (bytes.length > maxDownloadBytes) {
          throw const SubtitleProviderException(
            'Subtitle archive is too large.',
          );
        }
        onProgress?.call(bytes.length, total);
      }
      if (bytes.length == 0) {
        throw const SubtitleProviderException('Subtitle download was empty.');
      }
      return bytes.takeBytes();
    } on DioException catch (error) {
      throw SubtitleProviderException(_networkMessage(error));
    }
  }

  @override
  Future<String> accountStatus(String apiKey) async {
    if (apiKey.trim().isEmpty) return 'API key missing';
    try {
      final response = await _client.get<Map<String, dynamic>>(
        'https://api.subdl.com/api/v1/me',
        queryParameters: {'api_key': apiKey.trim()},
      );
      final data = response.data;
      if (data == null || data['status'] == false) {
        return _safeMessage(data?['error']);
      }
      return 'Connected to SubDL';
    } on DioException catch (error) {
      return _networkMessage(error);
    }
  }

  static String _safeMessage(Object? value) {
    final message = value is String
        ? value
        : 'SubDL could not complete this request.';
    return message.length > 180 ? '${message.substring(0, 180)}…' : message;
  }

  static String _networkMessage(DioException error) =>
      switch (error.response?.statusCode) {
        401 || 403 => 'SubDL API key is invalid or not authorized.',
        429 => 'SubDL rate limit or download quota reached. Try again later.',
        int status when status >= 500 => 'SubDL is temporarily unavailable.',
        _
            when error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout =>
          'SubDL timed out. Try again later.',
        _ => 'Could not reach SubDL. Check your connection.',
      };
}
