import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'playback_database.g.dart';

class PlaybackPositions extends Table {
  TextColumn get mediaId => text()();
  IntColumn get positionMs => integer()();
  IntColumn get durationMs => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {mediaId};
}

@DriftDatabase(tables: [PlaybackPositions])
class PlaybackDatabase extends _$PlaybackDatabase {
  PlaybackDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'gee_player'));

  @override
  int get schemaVersion => 1;

  Future<Duration?> positionFor(String mediaId) async {
    final row = await (select(playbackPositions)
          ..where((table) => table.mediaId.equals(mediaId)))
        .getSingleOrNull();
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
      await (delete(playbackPositions)
            ..where((table) => table.mediaId.equals(mediaId)))
          .go();
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
}
