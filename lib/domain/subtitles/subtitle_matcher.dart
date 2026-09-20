import 'package:gee_player/domain/subtitles/subtitle_candidate.dart';

/// Ranks release names conservatively: only a close match is applied silently.
class SubtitleMatcher {
  static final _episodePattern = RegExp(
    r's(\d{1,2})e(\d{1,2})',
    caseSensitive: false,
  );
  static final _yearPattern = RegExp(r'\b(19\d{2}|20\d{2})\b');
  static final _noise = RegExp(
    r'\b(480p|720p|1080p|2160p|4k|x264|x265|h264|h265|hevc|web|dl|webrip|bluray|brrip|hdrip|aac|mkv|mp4|avi|srt|vtt|ass)\b',
    caseSensitive: false,
  );

  static String normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'\.[^.]{2,4}$'), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(_noise, ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static double score(String fileName, SubtitleCandidate subtitle) {
    final input = normalize(fileName);
    final release = normalize(
      subtitle.releaseName.isEmpty ? subtitle.name : subtitle.releaseName,
    );
    if (input.isEmpty || release.isEmpty) return 0;
    final sourceEpisode = _episodePattern.firstMatch(fileName);
    final subtitleEpisode = _episodePattern.firstMatch(subtitle.releaseName);
    if (sourceEpisode != null &&
        subtitleEpisode != null &&
        (sourceEpisode.group(1) != subtitleEpisode.group(1) ||
            sourceEpisode.group(2) != subtitleEpisode.group(2))) {
      return 0;
    }
    if (sourceEpisode != null &&
        subtitle.season != null &&
        int.parse(sourceEpisode.group(1)!) != subtitle.season) {
      return 0;
    }
    if (sourceEpisode != null &&
        subtitle.episode != null &&
        int.parse(sourceEpisode.group(2)!) != subtitle.episode) {
      return 0;
    }
    final sourceYear = _yearPattern.firstMatch(fileName)?.group(0);
    final subtitleYear = _yearPattern
        .firstMatch(subtitle.releaseName)
        ?.group(0);
    if (sourceYear != null &&
        subtitleYear != null &&
        sourceYear != subtitleYear) {
      return 0;
    }
    if (input == release) return 1;
    final inputTokens = input.split(' ').toSet();
    final releaseTokens = release.split(' ').toSet();
    final shared = inputTokens.intersection(releaseTokens).length;
    return shared / inputTokens.union(releaseTokens).length;
  }

  static SubtitleCandidate? confidentMatch(
    String fileName,
    List<SubtitleCandidate> options,
    List<String> preferredLanguages,
  ) {
    for (final language in preferredLanguages) {
      final ranked =
          options
              .where(
                (candidate) =>
                    candidate.language.toUpperCase() == language.toUpperCase(),
              )
              .map((candidate) => (candidate, score(fileName, candidate)))
              .where((entry) => entry.$2 >= 0.8)
              .toList()
            ..sort((a, b) => b.$2.compareTo(a.$2));
      if (ranked.isEmpty) continue;
      if (ranked.length > 1 && ranked[0].$2 - ranked[1].$2 < 0.1) return null;
      return ranked.first.$1;
    }
    return null;
  }
}
