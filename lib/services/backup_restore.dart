import 'dart:io';

import 'package:diary_app/models/recording.dart';
import 'package:diary_app/services/google_drive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database_accessor.dart';

class BackupRestore {
  GoogleDrive drive = GoogleDrive();
  final DatabaseAccessor da = DatabaseAccessor();

  Future<bool> isBackupComplete() {
    // check database to determine if all files are backed up
  }

  void backup() async {
  Directory appDocDir;
//
  if (Platform.isAndroid) {
  appDocDir = await getExternalStorageDirectory();
  } else {
  appDocDir = await getApplicationDocumentsDirectory();
  }

  String appDocPath = appDocDir.path;


    drive.createFolder();


    List<Recording> recordings = await getRecordings();



    for (var r in recordings) {
      String fullDirPath = p.join(appDocPath, r.path);


      drive.upload(File(fullDirPath));
    }

    // 1. Check if backup folder has been set
    // if folder has been set
    // backup files to set folder
    // if no backup folder has been set
    // TODO: allow user to select backup folder
    // create folder
    // 2. Back up files
    // if file has not been backed up yet (check db), upload
    // mark file has uploaded in db
    // 3. Once all files are uploaded, back up db file
  }

  Future<List<Recording>> getRecordings() async {
    DateTime now = DateTime.now();
    DateTime startTime = DateTime.fromMillisecondsSinceEpoch(0);
    DateTime endTime = now;

    //TODO: find recordings that have not been backed up
    return da.recordings(startTime: startTime, endTime: endTime);
  }

// Backup

// Restore
// 1. have user select folder in drive
// 2. Check that folder contains database file and some recordings
// if current folder/database are empty
//    3. Download database file and recordings
// else merge in files and database
// 4. Set folder ID to be backup folder
}
