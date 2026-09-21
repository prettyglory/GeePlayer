import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/data/playback/playback_database.dart';
import 'package:gee_player/domain/media/local_media.dart';

void main() {
  late PlaybackDatabase database;

  setUp(() => database = PlaybackDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('restores progress after saving and clears it at completion', () async {
    const duration = Duration(minutes: 10);
    expect(await database.positionFor('video:1'), isNull);

    await database.savePosition(
      'video:1',
      const Duration(minutes: 3),
      duration,
    );
    expect(await database.positionFor('video:1'), const Duration(minutes: 3));

    await database.savePosition(
      'video:1',
      const Duration(minutes: 9, seconds: 58),
      duration,
    );
    expect(await database.positionFor('video:1'), isNull);
  });

  test('does not offer a resume position for a brief preview', () async {
    await database.savePosition(
      'audio:1',
      const Duration(seconds: 3),
      const Duration(minutes: 3),
    );
    expect(await database.positionFor('audio:1'), isNull);
  });

  test('stores favorites and ordered playlist items', () async {
    const song = LocalMedia(
      id: 'audio:1',
      kind: MediaKind.audio,
      uri: 'content://audio/1',
      fileName: 'First.mp3',
      folderPath: 'Music',
      artist: 'Gee',
    );
    const video = LocalMedia(
      id: 'video:1',
      kind: MediaKind.video,
      uri: 'content://video/1',
      fileName: 'Movie.mp4',
      folderPath: 'Movies',
    );

    expect(await database.toggleFavorite(song), isTrue);
    expect((await database.favoriteItems()).single.id, song.id);
    expect(await database.toggleFavorite(song), isFalse);
    expect(await database.favoriteItems(), isEmpty);

    final playlist = await database.createPlaylist('Road trip');
    await database.addToPlaylist(playlist, song);
    await database.addToPlaylist(playlist, video);
    expect((await database.playlistMedia(playlist)).map((item) => item.id), [
      song.id,
      video.id,
    ]);
    expect((await database.savedPlaylists()).single.itemCount, 2);
  });

  test('builds playback history and continue watching', () async {
    const video = LocalMedia(
      id: 'video:2',
      kind: MediaKind.video,
      uri: 'content://video/2',
      fileName: 'Series.mp4',
      folderPath: 'Shows',
      duration: Duration(minutes: 40),
    );

    await database.recordPlayback(video);
    await database.savePosition(
      video.id,
      const Duration(minutes: 12),
      video.duration!,
    );

    expect((await database.recentMedia()).single.id, video.id);
    final resumable = (await database.continueWatching()).single;
    expect(resumable.media.id, video.id);
    expect(resumable.position, const Duration(minutes: 12));

    await database.clearHistory();
    expect(await database.recentMedia(), isEmpty);
  });
}
