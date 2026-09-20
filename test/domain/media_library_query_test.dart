import 'package:flutter_test/flutter_test.dart';
import 'package:gee_player/domain/media/local_media.dart';
import 'package:gee_player/domain/media/media_library_query.dart';

void main() {
  const items = [
    LocalMedia(
      id: '1',
      kind: MediaKind.audio,
      uri: 'file:///one',
      fileName: 'Zulu.mp3',
      folderPath: 'Music/Old',
      artist: 'Singer',
      duration: Duration(seconds: 50),
      sizeBytes: 1000,
    ),
    LocalMedia(
      id: '2',
      kind: MediaKind.audio,
      uri: 'file:///two',
      fileName: 'Alpha.flac',
      folderPath: 'Music/New',
      duration: Duration(seconds: 200),
      sizeBytes: 5000,
    ),
  ];

  test('search finds title, artist, and folder without case sensitivity', () {
    expect(
      MediaLibraryQuery.searchAndSort(
        items,
        query: 'SINGER',
        sort: MediaSort.name,
      ).single.title,
      'Zulu',
    );
    expect(
      MediaLibraryQuery.searchAndSort(
        items,
        query: 'new',
        sort: MediaSort.name,
      ).single.title,
      'Alpha',
    );
  });

  test('sorting by name, duration, and size is deterministic', () {
    expect(
      MediaLibraryQuery.searchAndSort(
        items,
        query: '',
        sort: MediaSort.name,
      ).map((item) => item.title),
      ['Alpha', 'Zulu'],
    );
    expect(
      MediaLibraryQuery.searchAndSort(
        items,
        query: '',
        sort: MediaSort.duration,
      ).first.title,
      'Alpha',
    );
    expect(
      MediaLibraryQuery.searchAndSort(
        items,
        query: '',
        sort: MediaSort.size,
      ).first.title,
      'Alpha',
    );
  });
}
