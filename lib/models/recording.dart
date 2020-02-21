final String columnId = 'id';
final String columnTime = 'time';
final String columnPath = 'path';
final String tableRecording = 'recordings';

class Recording {
  int id;
  DateTime time;
  String path;
  final tableName = 'recordings';

  Recording({this.id, this.time, this.path});

  Map<String, dynamic> toMap() {
    int mapId = null;

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
    time = map[columnTime];
    path = map[columnPath];
  }
}

List<Recording> dummyData = [
  new Recording(id: 0, time: DateTime.now(), path: 'test.acc'),
  new Recording(id: 1, time: DateTime.now(), path: 'test1.acc'),
  new Recording(id: 2, time: DateTime.now(), path: 'test2.acc'),
];
