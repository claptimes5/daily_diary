import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'models/recording.dart';

class DatabaseAccessor {
  final String dbName = 'diary_app.db';

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

//  Future<Recording> insert(Recording recording) async {
//    recording.id = await db.insert(tableRecording, recording.toMap());
//    return recording;
//  }

  Future<void> insertModel(Recording recording) async {
    // Get a reference to the database.
    final Database db = await getDatabase();

    // Insert the Dog into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same dog is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      recording.tableName,
      recording.toMap(),
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

    print(whereClause);

    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await db.query('recordings', where: whereClause, whereArgs: whereArgs);

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      print(maps[i]['time']);
      return Recording(
        id: maps[i]['id'],
        time: DateTime.parse(maps[i]['time']),
        path: maps[i]['path'],
      );
    });
  }

  Future<int> delete(int id) async {
    final Database db = await getDatabase();

    return await db.delete('recordings', where: 'id = ?', whereArgs: [id]);
  }
}
