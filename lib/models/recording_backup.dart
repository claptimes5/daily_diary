import 'package:diary_app/models/db_model.dart';

class RecordingBackup implements DbModel {
  static final String tableName = 'recording_backups';
  final int id;
  final int recordingId;
  final String backupService;
  final String backupFileId;
  final DateTime createdAt;

  static final String tableSql = "CREATE TABLE IF NOT EXISTS recording_backups("
      "id INTEGER PRIMARY KEY autoincrement, "
      "recording_id INTEGER,"
      "backup_service TEXT,"
      "backup_file_id TEXT,"
      "created_at TEXT"
      ")";

  String getTableName() {
    return tableName;
  }

  RecordingBackup({this.id, this.createdAt, this.recordingId, this.backupService, this.backupFileId});

  Map<String, dynamic> toMap() {
    int mapId;

    if (id != null) {
      mapId = id;
    }

    return {
      'id': mapId,
      'recording_id': recordingId,
      'backup_service': backupService,
      'backup_file_id': backupFileId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}