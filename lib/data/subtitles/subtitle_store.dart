import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:gee_player/data/subtitles/subdl_provider.dart';
import 'package:gee_player/domain/subtitles/subtitle_candidate.dart';
import 'package:gee_player/domain/subtitles/subtitle_matcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoredSubtitle {
  const StoredSubtitle(this.file, this.language, this.source);
  final File file;
  final String language;
  final String source;
}

class SubtitleStore {
  SubtitleStore({this.root});

  final Directory? root;
  late final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  static const maxSubtitleBytes = 4 * 1024 * 1024;
  static const _extensions = {'srt', 'vtt', 'ass', 'ssa', 'sub'};

  Future<Directory> _directory() async {
    final base = root ?? await getApplicationSupportDirectory();
    final directory = Directory(
      '${base.path}${Platform.pathSeparator}subtitles',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  String _id(String mediaId) => sha256.convert(utf8.encode(mediaId)).toString();

  Future<List<StoredSubtitle>> cachedFor(String mediaId) async {
    final directory = await _directory();
    final prefix = '${_id(mediaId)}.';
    final found = <StoredSubtitle>[];
    await for (final entry in directory.list()) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.last;
      if (!name.startsWith(prefix)) continue;
      final parts = name.substring(prefix.length).split('.');
      if (parts.length != 2 || !_extensions.contains(parts.last)) continue;
      final source = switch (parts.first) {
        'imported' => 'Imported',
        'local' => 'Local',
        _ => 'SubDL',
      };
      found.add(StoredSubtitle(entry, parts.first.toUpperCase(), source));
    }
    found.sort(
      (a, b) => a.source == b.source
          ? a.file.path.compareTo(b.file.path)
          : a.source == 'Imported' ||
                (a.source == 'Local' && b.source == 'SubDL')
          ? -1
          : 1,
    );
    return found;
  }

  Future<StoredSubtitle> importFile(String mediaId, XFile source) async {
    final extension = _extension(source.name);
    if (extension == null) {
      throw const SubtitleProviderException(
        'Choose an SRT, VTT, ASS, SSA or SUB file.',
      );
    }
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty || bytes.length > maxSubtitleBytes) {
      throw const SubtitleProviderException(
        'Subtitle must be between 1 byte and 4 MB.',
      );
    }
    return _save(mediaId, bytes, 'imported', extension, 'Imported');
  }

  Future<StoredSubtitle> saveCompanion(
    String mediaId,
    String name,
    List<int> bytes,
  ) async {
    final extension = _extension(name);
    if (extension == null || bytes.isEmpty || bytes.length > maxSubtitleBytes) {
      throw const SubtitleProviderException(
        'Local subtitle is invalid or too large.',
      );
    }
    return _save(mediaId, bytes, 'local', extension, 'Local');
  }

  Future<StoredSubtitle> saveDownload(
    String mediaId,
    String mediaFileName,
    SubtitleCandidate candidate,
    List<int> bytes,
  ) async {
    if (candidate.isArchive) {
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      if (archive.length > 100) {
        throw const SubtitleProviderException(
          'Subtitle archive has too many files.',
        );
      }
      final entries = archive.files
          .where(
            (entry) =>
                entry.isFile &&
                !entry.isSymbolicLink &&
                entry.size > 0 &&
                entry.size <= maxSubtitleBytes &&
                !entry.name.contains('..') &&
                _extension(entry.name) != null,
          )
          .toList();
      if (entries.isEmpty) {
        throw const SubtitleProviderException(
          'Archive has no supported subtitle file.',
        );
      }
      ArchiveFile? selected;
      if (entries.length == 1) {
        selected = entries.first;
      } else {
        entries.sort(
          (a, b) =>
              SubtitleMatcher.score(
                mediaFileName,
                SubtitleCandidate(
                  name: b.name,
                  releaseName: b.name,
                  language: candidate.language,
                  downloadPath: candidate.downloadPath,
                ),
              ).compareTo(
                SubtitleMatcher.score(
                  mediaFileName,
                  SubtitleCandidate(
                    name: a.name,
                    releaseName: a.name,
                    language: candidate.language,
                    downloadPath: candidate.downloadPath,
                  ),
                ),
              ),
        );
        final topScore = SubtitleMatcher.score(
          mediaFileName,
          SubtitleCandidate(
            name: entries.first.name,
            releaseName: entries.first.name,
            language: candidate.language,
            downloadPath: candidate.downloadPath,
          ),
        );
        if (topScore < 0.8) {
          throw const SubtitleProviderException(
            'Archive contains several subtitles; choose a more exact match.',
          );
        }
        selected = entries.first;
      }
      final content = selected.readBytes();
      if (content == null ||
          content.isEmpty ||
          content.length > maxSubtitleBytes) {
        throw const SubtitleProviderException(
          'Invalid subtitle file in archive.',
        );
      }
      return _save(
        mediaId,
        content,
        candidate.language,
        _extension(selected.name)!,
        'SubDL',
      );
    }
    final extension = _extension(candidate.name) ?? 'srt';
    if (bytes.isEmpty || bytes.length > maxSubtitleBytes) {
      throw const SubtitleProviderException(
        'Subtitle file is invalid or too large.',
      );
    }
    return _save(mediaId, bytes, candidate.language, extension, 'SubDL');
  }

  Future<StoredSubtitle> _save(
    String mediaId,
    List<int> bytes,
    String language,
    String extension,
    String source,
  ) async {
    final directory = await _directory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}${_id(mediaId)}.${language.toLowerCase()}.$extension',
    );
    final temporary = File('${file.path}.part');
    await temporary.writeAsBytes(bytes, flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
    return StoredSubtitle(file, language.toUpperCase(), source);
  }

  static String? _extension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return null;
    final extension = name.substring(dot + 1).toLowerCase();
    return _extensions.contains(extension) ? extension : null;
  }

  Future<bool> isNegativeCached(String mediaId, String language) async {
    final timestamp = await _prefs.getInt(
      'subtitle.miss.${_id(mediaId)}.$language',
    );
    return timestamp != null &&
        DateTime.now().millisecondsSinceEpoch - timestamp <
            const Duration(hours: 24).inMilliseconds;
  }

  Future<void> recordNegative(String mediaId, String language) => _prefs.setInt(
    'subtitle.miss.${_id(mediaId)}.$language',
    DateTime.now().millisecondsSinceEpoch,
  );

  Future<void> clearNegative(String mediaId, String language) =>
      _prefs.remove('subtitle.miss.${_id(mediaId)}.$language');
}
