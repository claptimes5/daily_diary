import 'dart:io';

import 'package:diary_app/models/recording.dart';
import 'package:diary_app/models/recording_backup.dart';
import 'package:diary_app/services/google_drive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database_accessor.dart';
import 'package:shared_preferences/shared_preferences.dart';


class BackupRestore {
  GoogleDrive drive = GoogleDrive();
  final DatabaseAccessor da = DatabaseAccessor();
  SharedPreferences prefs;
  final String googleDriveBackupFolderIdKey =
      'google_drive_backup_folder';
  static final String lastBackupAtKey = 'last_backup_at';

  // Check database to determine if all files are backed up
  Future<bool> isBackupComplete() async {
    return (await recordingsNotBackedUpCount() == 0);
  }

  // Get count of all recordings that occurred after our DB was last backed up
  Future<int> recordingsNotBackedUpCount() async {
    await loadPrefs();
    // TODO: Use DB to make this more peformant
    String lastBackupDateIsoString = prefs.getString(lastBackupAtKey);
    DateTime lastBackupDate;

    if (lastBackupDateIsoString != null) {
      lastBackupDate = DateTime.parse(lastBackupDateIsoString);


    }
      List<Recording> recordings = await da.recordings(startTime: lastBackupDate);

      return recordings.length;
  }

  Future<void> loadPrefs() async {
    if (prefs == null) {
      prefs = await SharedPreferences.getInstance();
    }
  }

  // Create backup folder on Drive if it does not already exist
  Future<void> createBackupFolder() async {
    await loadPrefs();
    String folderId = prefs.getString(
        googleDriveBackupFolderIdKey);

    // If there is no folder ID set or if there is a folder ID
    // but no actual folder in the drive, we should create a folder
    if (folderId == null ||
        (folderId != null && !(await drive.folderExists(folderId)))) {
      folderId = await drive.createFolder();
      prefs.setString(googleDriveBackupFolderIdKey, folderId);
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

  // 1. Check if backup folder has been set
  //    If folder has been set
  // backup files to set folder
  //    If no backup folder has been set: create folder
  //    TODO: allow user to select backup folder
  // 2. Back up files
  // if file has not been backed up yet, upload
  //    - mark file has uploaded in db
  // 3. Once all files are uploaded, back up db file
  void backup() async {
    loadPrefs();
//    await da.createRecordingBackupsTable();
    await createBackupFolder();

    List<Recording> recordings = await da.recordingsToBackup();
    String appDocPath = await getLocalRecordingsFolder();

    for (var r in recordings) {
      String fullDirPath = p.join(appDocPath, r.path);

      // Upload file to Google Drive and store record of backup in DB if succeeded
      if (await drive.upload(File(fullDirPath))) {
        await da.insertModel(RecordingBackup(createdAt: DateTime.now(),
            recordingId: r.id,
            backupService: 'google_drive'));
      } else {
        print('Failed to upload recording: ${r.path}');
      }
    }

    // Upload database file
    if (await drive.upload(File((await da.getDatabase()).path))) {
      prefs.setString(lastBackupAtKey, DateTime.now().toIso8601String());
    } else {
      print('Backup of database failed');
    }
  }

  // Clear out the backup history table so that we can force a new backup to current backup target
  void resetBackupHistory() {
    da.delete(RecordingBackup.tableName, null);
  }

  // TODO:
// Restore
// 1. have user select folder in drive
// 2. Check that folder contains database file and some recordings
// if current folder/database are empty
//    3. Download database file and recordings
// else merge in files and database
// 4. Set folder ID to be backup folder
}
