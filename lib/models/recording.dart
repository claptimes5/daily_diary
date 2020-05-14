import 'package:diary_app/models/db_model.dart';

final String columnId = 'id';
final String columnTime = 'time';
final String columnPath = 'path';
final String tableRecording = 'recordings';

class Recording implements DbModel {
  int id;
  DateTime time;
  String path;
  static final tableName = 'recordings';

  String getTableName() {
    return tableName;
  }

  Recording({this.id, this.time, this.path});

  Map<String, dynamic> toMap() {
    int mapId;

    if (id != null) {
      mapId = id;
    }

    return {
      'id': mapId,
      'time': time.toIso8601String(),
      'path': path,
    };
  }

  @override
  String toString() {
    final String time = this.time.toIso8601String();
    return 'Recording{id: $id, time: $time, path: $path}';
  }

  Recording.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    time = DateTime.parse(map[columnTime]);
    path = map[columnPath];
  }
}

