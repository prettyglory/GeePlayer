import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/domain/subtitles/subtitle_candidate.dart';
import 'package:gee_player/domain/subtitles/subtitle_matcher.dart';

SubtitleCandidate option(
  String release,
  String language, {
  int? season,
  int? episode,
}) => SubtitleCandidate(
  name: '$release.srt',
  releaseName: release,
  language: language,
  downloadPath: '/subtitle/example.zip',
  season: season,
  episode: episode,
);

void main() {
  test('prefers a confident Kiswahili release match', () {
    final file = 'Breaking.Bad.S05E14.1080p.BluRay.x264-DEMAND.mkv';
    final sw = option('Breaking.Bad.S05E14.1080p.BluRay.x264-DEMAND', 'SW');
    final en = option('Breaking.Bad.S05E14.1080p.BluRay.x264-DEMAND', 'EN');
    expect(SubtitleMatcher.confidentMatch(file, [en, sw], ['SW', 'EN']), sw);
  });

  test('rejects a different episode even when title matches', () {
    final file = 'Breaking.Bad.S05E14.1080p.BluRay.mkv';
    final wrong = option(
      'Breaking.Bad.S05E13.1080p.BluRay',
      'SW',
      season: 5,
      episode: 13,
    );
    expect(SubtitleMatcher.score(file, wrong), 0);
    expect(SubtitleMatcher.confidentMatch(file, [wrong], ['SW', 'EN']), isNull);
  });

  test('requires manual choice for equally strong releases', () {
    final file = 'Movie.2024.1080p.WEB.mkv';
    final first = option('Movie.2024.1080p.WEB', 'EN');
    final second = option('Movie.2024.1080p.WEB-DL', 'EN');
    expect(
      SubtitleMatcher.confidentMatch(file, [first, second], ['EN']),
      isNull,
    );
  });

  test('rejects conflicting release years', () {
    expect(
      SubtitleMatcher.score('Dune.2021.mkv', option('Dune.1984', 'EN')),
      0,
    );
  });
}
