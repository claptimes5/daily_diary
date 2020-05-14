import 'package:diary_app/models/db_model.dart';
import 'package:diary_app/models/recording_backup.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'models/recording.dart';

class DatabaseAccessor {
  static final String dbName = 'diary_app.db';

  void initDatabase() async {
    await createRecordingsTable();
    await createRecordingBackupsTable();
  }

  Future<Database> getDatabase() async {
    return openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), dbName),
    );
  }

  Future<Database> createRecordingsTable() async {
    return openDatabase(
      join(await getDatabasesPath(), dbName),

      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE recordings(id INTEGER PRIMARY KEY autoincrement, time TEXT, path TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<Database> createRecordingBackupsTable() async {
    print('creating recording_backups table');
    final Database db = await getDatabase();
    await db.execute(RecordingBackup.tableSql);
  }

//  Future<Recording> insert(Recording recording) async {
//    recording.id = await db.insert(tableRecording, recording.toMap());
//    return recording;
//  }

  Future<void> insertModel(DbModel model) async {
    // Get a reference to the database.
    final Database db = await getDatabase();

    // Insert the Dog into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same model is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      model.getTableName(),
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Recording>> recordings({DateTime startTime, DateTime endTime}) async {
    final Database db = await getDatabase();
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startTime != null) {
      whereClause += 'time >= ?';
      whereArgs.add(startTime.toIso8601String());
    }

    if (endTime != null) {
      if (whereClause.length > 0) {
        whereClause += ' AND ';
      }

      whereClause += 'time <= ?';
      whereArgs.add(endTime.toIso8601String());
    }

    List<Map<String, dynamic>> maps;
    if (whereClause.length > 0) {
      // Query the table for all The Dogs.
      maps =
      await db.query('recordings', where: whereClause, whereArgs: whereArgs);
    } else {
      maps = await db.query('recordings');
    }

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      return Recording(
        id: maps[i]['id'],
        time: DateTime.parse(maps[i]['time']),
        path: maps[i]['path'],
      );
    });
  }

  Future<int> deleteRecording(int id) async {
    return await delete(Recording.tableName, id);
  }
  
  Future<int> delete(String tableName, int id) async {
    final Database db = await getDatabase();

    // Delete all
    if (id == null) {
      return await db.delete(tableName);
    } else {
      return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
    }
  }

  // Get list of recordings that have not yet been backed up
  Future<List<Recording>> recordingsToBackup() async {
    final String recordingsToBackupSql = 'SELECT r.* '
        'FROM recordings r '
        'where r.id not in (SELECT recording_id FROM recording_backups)';
    final Database db = await getDatabase();

    final List<Map<String, dynamic>> maps = await db.rawQuery(
        recordingsToBackupSql);

    // Convert the List<Map<String, dynamic> into a List<Recording>.
    return List.generate(maps.length, (i) {
      return Recording.fromMap(maps[i]);
    });
  }
}
