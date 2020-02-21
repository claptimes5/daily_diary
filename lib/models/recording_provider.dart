import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'recording.dart';

class RecordingProvider {
  Database db;

  Future open(String path) async {
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
create table $tableRecording ( 
  $columnId integer primary key autoincrement, 
  $columnTime text not null,
  $columnPath text not null)
''');
        });
  }

  Future<Recording> insert(Recording recording) async {
    recording.id = await db.insert(tableRecording, recording.toMap());
    return recording;
  }

  Future<Recording> getRecording(int id) async {
    List<Map> maps = await db.query(tableRecording,
        columns: [columnId, columnTime, columnPath],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return Recording.fromMap(maps.first);
    }
    return null;
  }

  Future<int> delete(int id) async {
    return await db.delete(tableRecording, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> update(Recording recording) async {
    return await db.update(tableRecording, recording.toMap(),
        where: '$columnId = ?', whereArgs: [recording.id]);
  }

  Future<List<Map<String, dynamic>>> recordings() async {
    return await db.query('recordings');
  }

  Future close() async => db.close();
}