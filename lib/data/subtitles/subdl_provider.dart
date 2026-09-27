import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:gee_player/domain/subtitles/subtitle_candidate.dart';

class SubtitleProviderException implements Exception {
  const SubtitleProviderException(this.message);

  final String message;

  @override
  String toString() => message;
}

const subdlKeyMissingMessage =
    'Online subtitle search is not configured. Start Gee Player with '
    '--dart-define=SUBDL_API_KEY=YOUR_KEY.';

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
      throw const SubtitleProviderException(subdlKeyMissingMessage);
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
          'comment': 1,
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
        throw SubtitleProviderException(_safeMessage(body['error'], apiKey));
      }

      final rows = body['subtitles'];

      if (rows is! List) {
        return const [];
      }

      final candidates = <SubtitleCandidate>[];

      for (final row in rows) {
        if (row is! Map) {
          continue;
        }

        final parent = Map<String, dynamic>.from(row);
        final unpacked = parent['unpack_files'];

        if (unpacked is List && unpacked.isNotEmpty) {
          for (final item in unpacked) {
            if (item is Map) {
              final candidate = _parseCandidate(
                Map<String, dynamic>.from(item),
                parent,
              );

              if (candidate != null) {
                candidates.add(candidate);
              }
            }
          }
        } else {
          final candidate = _parseCandidate(parent, parent);

          if (candidate != null) {
            candidates.add(candidate);
          }
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
    final path = _normalizeDownloadPath(row['url']);

    if (path == null) {
      return null;
    }

    final name = (row['name'] ?? parent['name'] ?? '').toString();

    final release = (row['release_name'] ?? parent['release_name'] ?? name)
        .toString();

    final language = _languageCode(
      (row['language'] ?? row['lang'] ?? parent['language'] ?? parent['lang'])
          ?.toString(),
    );

    if (language == null) {
      return null;
    }

    return SubtitleCandidate(
      name: name,
      releaseName: release,
      language: language,
      downloadPath: path,
      season: _number(row['season'] ?? parent['season']),
      episode: _number(row['episode'] ?? parent['episode']),
      author: _optionalText(
        row['author'] ??
            row['uploader'] ??
            row['uploaded_by'] ??
            parent['author'] ??
            parent['uploader'] ??
            parent['uploaded_by'],
      ),
      fps: _decimal(row['fps'] ?? parent['fps']),
      format: _optionalText(row['format'] ?? parent['format']),
    );
  }

  static int? _number(Object? value) =>
      value is int ? value : int.tryParse('$value');

  static double? _decimal(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value');

  static String? _optionalText(Object? value) {
    final text = value?.toString().trim();

    return text == null || text.isEmpty ? null : text;
  }

  static String? _languageCode(String? value) {
    if (value == null) {
      return null;
    }

    return switch (value.toLowerCase()) {
      'en' || 'eng' || 'english' => 'EN',
      'sw' || 'swa' || 'swahili' || 'kiswahili' => 'SW',
      _ => null,
    };
  }

  /// Normalizes a SubDL subtitle download URL.
  ///
  /// SubDL may return URLs such as:
  ///
  /// /subtitle/example.zip?api_key=...
  ///
  /// Gee Player only stores the safe /subtitle/... path.
  /// Query parameters are intentionally removed so the API key
  /// is never stored inside SubtitleCandidate.
  static String? _normalizeDownloadPath(Object? value) {
    if (value is! String) {
      return null;
    }

    final raw = value.trim();

    if (raw.isEmpty || raw.contains(r'\')) {
      return null;
    }

    final uri = Uri.tryParse(raw);

    if (uri == null) {
      return null;
    }

    // Only relative SubDL paths are accepted.
    // Reject external/absolute URLs.
    if (uri.hasScheme || uri.hasAuthority) {
      return null;
    }

    // Fragments are not expected in SubDL download URLs.
    if (uri.hasFragment) {
      return null;
    }

    // IMPORTANT:
    // uri.path removes ?api_key=... and any other query parameters.
    final path = uri.path;

    if (path.isEmpty || path.contains('..') || path.contains(r'\')) {
      return null;
    }

    final normalized = path.startsWith('/') ? path : '/$path';

    if (!normalized.startsWith('/subtitle/')) {
      return null;
    }

    return normalized;
  }

  @override
  Future<List<int>> download(
    SubtitleCandidate candidate, {
    required String apiKey,
    void Function(int received, int total)? onProgress,
  }) async {
    final path = _normalizeDownloadPath(candidate.downloadPath);

    if (path == null) {
      throw const SubtitleProviderException('Invalid subtitle download link.');
    }

    try {
      // SubDL documents anonymous downloads for free keys.
      // Never put the API key into the download URL here.
      final response = await _client.get<ResponseBody>(
        Uri.https('dl.subdl.com', path).toString(),
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
    if (apiKey.trim().isEmpty) {
      return 'API key missing';
    }

    try {
      final response = await _client.get<Map<String, dynamic>>(
        'https://api.subdl.com/api/v1/me',
        queryParameters: {'api_key': apiKey.trim()},
      );

      final data = response.data;

      if (data == null || data['status'] == false) {
        return _safeMessage(data?['error'], apiKey);
      }

      return 'Connected to SubDL';
    } on DioException catch (error) {
      return _networkMessage(error);
    }
  }

  static String _safeMessage(Object? value, [String? secret]) {
    var message = value is String
        ? value
        : 'SubDL could not complete this request.';

    final redacted = secret?.trim();

    if (redacted != null && redacted.isNotEmpty) {
      message = message.replaceAll(redacted, '[redacted]');
    }

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
