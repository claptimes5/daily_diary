import 'dart:async';
import 'dart:io';

import 'package:diary_app/services/google_drive.dart';
import 'package:path_provider/path_provider.dart';
import '../../database_accessor.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BackupRestore {
  GoogleDrive drive = GoogleDrive();
  final DatabaseAccessor da = DatabaseAccessor();
  SharedPreferences prefs;
  final String googleDriveBackupFolderIdKey = 'google_drive_backup_folder';
  final String databaseFileIdKey = 'google_drive_database_file_id';

  Future<void> loadPrefs() async {
    if (prefs == null) {
      prefs = await SharedPreferences.getInstance();
    }
  }

  Future<String> getLocalRecordingsFolder() async {
    Directory appDocDir;

    if (Platform.isAndroid) {
      appDocDir = await getExternalStorageDirectory();
    } else {
      appDocDir = await getApplicationDocumentsDirectory();
    }

    return appDocDir.path;
  }
}
