import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:gee_player/domain/media/local_media.dart';

part 'playback_database.g.dart';

class PlaybackPositions extends Table {
  TextColumn get mediaId => text()();
  IntColumn get positionMs => integer()();
  IntColumn get durationMs => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {mediaId};
}

class MediaRecords extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get uri => text()();
  TextColumn get fileName => text()();
  TextColumn get folderPath => text()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  DateTimeColumn get dateAdded => dateTime().nullable()();
  TextColumn get mimeType => text().nullable()();
  TextColumn get artist => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class FavoriteMedia extends Table {
  TextColumn get mediaId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {mediaId};
}

class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PlaylistItems extends Table {
  TextColumn get playlistId => text()();
  TextColumn get mediaId => text()();
  IntColumn get position => integer()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {playlistId, mediaId};
}

class PlaybackHistory extends Table {
  TextColumn get mediaId => text()();
  DateTimeColumn get lastPlayedAt => dateTime()();
  IntColumn get playCount => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {mediaId};
}

class SavedPlaylist {
  const SavedPlaylist({
    required this.id,
    required this.name,
    required this.itemCount,
  });

  final String id;
  final String name;
  final int itemCount;
}

class ContinueWatchingItem {
  const ContinueWatchingItem({required this.media, required this.position});

  final LocalMedia media;
  final Duration position;
}

@DriftDatabase(
  tables: [
    PlaybackPositions,
    MediaRecords,
    FavoriteMedia,
    Playlists,
    PlaylistItems,
    PlaybackHistory,
  ],
)
class PlaybackDatabase extends _$PlaybackDatabase {
  PlaybackDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'gee_player'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(mediaRecords);
        await migrator.createTable(favoriteMedia);
        await migrator.createTable(playlists);
        await migrator.createTable(playlistItems);
        await migrator.createTable(playbackHistory);
      }
    },
  );

  Future<Duration?> positionFor(String mediaId) async {
    final row = await (select(
      playbackPositions,
    )..where((table) => table.mediaId.equals(mediaId))).getSingleOrNull();
    return row == null ? null : Duration(milliseconds: row.positionMs);
  }

  Future<void> savePosition(
    String mediaId,
    Duration position,
    Duration duration,
  ) async {
    final elapsed = position.inMilliseconds;
    final total = duration.inMilliseconds;
    if (elapsed < 5000 || (total > 0 && elapsed >= total - 5000)) {
      await (delete(
        playbackPositions,
      )..where((table) => table.mediaId.equals(mediaId))).go();
      return;
    }
    await into(playbackPositions).insertOnConflictUpdate(
      PlaybackPositionsCompanion.insert(
        mediaId: mediaId,
        positionMs: elapsed,
        durationMs: total,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> upsertMedia(LocalMedia media) =>
      into(mediaRecords).insertOnConflictUpdate(_mediaCompanion(media));

  Future<bool> toggleFavorite(LocalMedia media) async {
    await upsertMedia(media);
    final existing = await (select(
      favoriteMedia,
    )..where((table) => table.mediaId.equals(media.id))).getSingleOrNull();
    if (existing != null) {
      await (delete(
        favoriteMedia,
      )..where((table) => table.mediaId.equals(media.id))).go();
      return false;
    }
    await into(favoriteMedia).insert(
      FavoriteMediaCompanion.insert(
        mediaId: media.id,
        createdAt: DateTime.now(),
      ),
    );
    return true;
  }

  Future<Set<String>> favoriteIds() async =>
      (await select(favoriteMedia).get()).map((row) => row.mediaId).toSet();

  Future<List<LocalMedia>> favoriteItems() async {
    final query = select(favoriteMedia).join([
      innerJoin(mediaRecords, mediaRecords.id.equalsExp(favoriteMedia.mediaId)),
    ])..orderBy([OrderingTerm.desc(favoriteMedia.createdAt)]);
    return (await query.get())
        .map((row) => _toMedia(row.readTable(mediaRecords)))
        .toList();
  }

  Future<String> createPlaylist(String name) async {
    final now = DateTime.now();
    final id = 'playlist:${now.microsecondsSinceEpoch}';
    await into(playlists).insert(
      PlaylistsCompanion.insert(
        id: id,
        name: name.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  Future<void> renamePlaylist(String id, String name) =>
      (update(playlists)..where((table) => table.id.equals(id))).write(
        PlaylistsCompanion(
          name: Value(name.trim()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deletePlaylist(String id) => transaction(() async {
    await (delete(
      playlistItems,
    )..where((table) => table.playlistId.equals(id))).go();
    await (delete(playlists)..where((table) => table.id.equals(id))).go();
  });

  Future<void> addToPlaylist(String playlistId, LocalMedia media) =>
      transaction(() async {
        await upsertMedia(media);
        final positionExpression = playlistItems.position.max();
        final positionQuery = selectOnly(playlistItems)
          ..addColumns([positionExpression])
          ..where(playlistItems.playlistId.equals(playlistId));
        final row = await positionQuery.getSingle();
        final nextPosition = (row.read(positionExpression) ?? -1) + 1;
        await into(playlistItems).insertOnConflictUpdate(
          PlaylistItemsCompanion.insert(
            playlistId: playlistId,
            mediaId: media.id,
            position: nextPosition,
            addedAt: DateTime.now(),
          ),
        );
        await (update(playlists)..where((table) => table.id.equals(playlistId)))
            .write(PlaylistsCompanion(updatedAt: Value(DateTime.now())));
      });

  Future<void> removeFromPlaylist(String playlistId, String mediaId) =>
      (delete(playlistItems)..where(
            (table) =>
                table.playlistId.equals(playlistId) &
                table.mediaId.equals(mediaId),
          ))
          .go();

  Future<List<SavedPlaylist>> savedPlaylists() async {
    final count = playlistItems.mediaId.count();
    final query =
        select(playlists).join([
            leftOuterJoin(
              playlistItems,
              playlistItems.playlistId.equalsExp(playlists.id),
            ),
          ])
          ..addColumns([count])
          ..groupBy([playlists.id])
          ..orderBy([OrderingTerm.desc(playlists.updatedAt)]);
    return (await query.get())
        .map(
          (row) => SavedPlaylist(
            id: row.readTable(playlists).id,
            name: row.readTable(playlists).name,
            itemCount: row.read(count) ?? 0,
          ),
        )
        .toList();
  }

  Future<List<LocalMedia>> playlistMedia(String playlistId) async {
    final query =
        select(playlistItems).join([
            innerJoin(
              mediaRecords,
              mediaRecords.id.equalsExp(playlistItems.mediaId),
            ),
          ])
          ..where(playlistItems.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm.asc(playlistItems.position)]);
    return (await query.get())
        .map((row) => _toMedia(row.readTable(mediaRecords)))
        .toList();
  }

  Future<void> recordPlayback(LocalMedia media) => transaction(() async {
    await upsertMedia(media);
    final existing = await (select(
      playbackHistory,
    )..where((table) => table.mediaId.equals(media.id))).getSingleOrNull();
    await into(playbackHistory).insertOnConflictUpdate(
      PlaybackHistoryCompanion.insert(
        mediaId: media.id,
        lastPlayedAt: DateTime.now(),
        playCount: Value((existing?.playCount ?? 0) + 1),
      ),
    );
  });

  Future<List<LocalMedia>> recentMedia({int limit = 30}) async {
    final query =
        select(playbackHistory).join([
            innerJoin(
              mediaRecords,
              mediaRecords.id.equalsExp(playbackHistory.mediaId),
            ),
          ])
          ..orderBy([OrderingTerm.desc(playbackHistory.lastPlayedAt)])
          ..limit(limit);
    return (await query.get())
        .map((row) => _toMedia(row.readTable(mediaRecords)))
        .toList();
  }

  Future<List<ContinueWatchingItem>> continueWatching({int limit = 20}) async {
    final query =
        select(playbackPositions).join([
            innerJoin(
              mediaRecords,
              mediaRecords.id.equalsExp(playbackPositions.mediaId),
            ),
          ])
          ..where(mediaRecords.kind.equals(MediaKind.video.name))
          ..orderBy([OrderingTerm.desc(playbackPositions.updatedAt)])
          ..limit(limit);
    return (await query.get())
        .map(
          (row) => ContinueWatchingItem(
            media: _toMedia(row.readTable(mediaRecords)),
            position: Duration(
              milliseconds: row.readTable(playbackPositions).positionMs,
            ),
          ),
        )
        .toList();
  }

  Future<void> clearHistory() => delete(playbackHistory).go();

  MediaRecordsCompanion _mediaCompanion(LocalMedia media) =>
      MediaRecordsCompanion.insert(
        id: media.id,
        kind: media.kind.name,
        uri: media.uri,
        fileName: media.fileName,
        folderPath: media.folderPath,
        durationMs: Value(media.duration?.inMilliseconds),
        sizeBytes: Value(media.sizeBytes),
        dateAdded: Value(media.dateAdded),
        mimeType: Value(media.mimeType),
        artist: Value(media.artist),
        updatedAt: DateTime.now(),
      );

  LocalMedia _toMedia(MediaRecord row) => LocalMedia(
    id: row.id,
    kind: MediaKind.values.byName(row.kind),
    uri: row.uri,
    fileName: row.fileName,
    folderPath: row.folderPath,
    duration: row.durationMs == null
        ? null
        : Duration(milliseconds: row.durationMs!),
    sizeBytes: row.sizeBytes,
    dateAdded: row.dateAdded,
    mimeType: row.mimeType,
    artist: row.artist,
  );
}
