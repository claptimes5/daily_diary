import 'dart:async';
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
  final String googleDriveBackupFolderIdKey = 'google_drive_backup_folder';
  final String databaseFileIdKey = 'google_drive_database_file_id';
  static final String lastBackupAtKey = 'last_backup_at';
  StreamController<BackupRestoreStatus> _backupRestoreController = StreamController.broadcast();
  Stream<BackupRestoreStatus> get onBackupRestoreStarted => _backupRestoreController.stream;

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
  Future<String> createBackupFolder() async {
    await loadPrefs();
    String folderId = prefs.getString(googleDriveBackupFolderIdKey);

    // If there is no folder ID set or if there is a folder ID
    // but no actual folder in the drive, we should create a folder
    if (folderId == null ||
        (folderId != null && !(await drive.folderExists(folderId)))) {
      folderId = await drive.createFolder();
      prefs.setString(googleDriveBackupFolderIdKey, folderId);
    }

    return folderId;
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
  Future<void> backup() async {
    try {
      loadPrefs();

      // Ensure the recording_backups table exists to store the backup history
      await da.createRecordingBackupsTable();

      // Create folder on Drive to use for our uploaded files
      String folderId = await createBackupFolder();
      List<String> folder = [folderId];

      List<Recording> recordings = await da.recordingsToBackup();
      String appDocPath = await getLocalRecordingsFolder();

      // Total files include all recordings plus the database file
      int totalFilesToBackup = recordings.length + 1;

      // Upload all recordings
      for (int i = 0; i < recordings.length; i++) {
        Recording r = recordings[i];

        String path = r.path;
        // Versions of the app > 0.1.1 use relative path to store files. This determines if
        // a relative path was used and prepends the appropriate path prefix.
        if (path.startsWith('/')) {
          // Split the absolute path and the prepend the file name with the diary entries directory
          // to construct the appropriate relative path
          path = path
              .split('/')
              .last;
          path = p.join('diary_entries', path);
        }

        String fullDirPath = p.join(appDocPath, path);

        // Upload file to Google Drive and store record of backup in DB if succeeded
        String fileId = await drive.upload(File(fullDirPath), folder);

        if (fileId != null) {
          await da.insertModel(RecordingBackup(
              createdAt: DateTime.now(),
              recordingId: r.id,
              backupFileId: fileId,
              backupService: 'google_drive'));
        } else {
          print('Failed to upload recording: ${r.path}');
        }

        _updateBackupRestoreProgress(i + 1, totalFilesToBackup);
      }

      // Upload database file now that all recordings have been marked as backed up
      String databaseFileId = prefs.getString(databaseFileIdKey);
      File databaseFile = File((await da.getDatabase()).path);
      bool fileUpdated = false;

      if (databaseFileId == null) {
        // Upload database file for the first time
        databaseFileId = await drive.upload(databaseFile, folder);
        prefs.setString(databaseFileIdKey, databaseFileId);
        fileUpdated = true;
      } else {
        fileUpdated = await drive.update(databaseFile, databaseFileId);
      }

      _updateBackupRestoreProgress(totalFilesToBackup, totalFilesToBackup);

      // Store the last time that a backup was successful
      if (fileUpdated) {
        prefs.setString(lastBackupAtKey, DateTime.now().toIso8601String());
      } else {
        print('Backup of database failed');
      }

      _removeBackupRestoreCallback();
    } on Exception catch (e) {
      throw BackupRestoreException(e.toString());
    }
  }

  // Clear out the backup history table so that we can force a new backup to current backup target
  void resetBackupHistory() {
//    da.delete(RecordingBackup.tableName, null);
    da.dropTable(RecordingBackup.tableName);
    prefs.setString(databaseFileIdKey, null);
    prefs.setString(lastBackupAtKey, null);
  }

// TODO:
// Restore
// 1. have user select folder in drive
// 2. Check that folder contains database file and some recordings
// if current folder/database are empty
//    3. Download database file and recordings
// else merge in files and database
// 4. Set folder ID to be backup folder

  void _updateBackupRestoreProgress(int currentFileIndex, int totalFiles) {
    _backupRestoreController.add(BackupRestoreStatus(currentFileIndex, totalFiles));
  }

  Future<void> _setBackupRestoreCallback() async {
    if (_backupRestoreController == null) {
      _backupRestoreController = StreamController.broadcast();
    }
  }

  void _removeBackupRestoreCallback() {
    if (_backupRestoreController != null) {
      _backupRestoreController
        ..add(null)
        ..close();
      _backupRestoreController = null;
    }
  }

  // Initialize the stream controller
  void prepare() {
    _setBackupRestoreCallback();
  }
}

class BackupRestoreStatus {
  final int currentItem;
  final int totalItems;

  BackupRestoreStatus(this.currentItem, this.totalItems);
}

class BackupRestoreException implements Exception {
  final String previousExceptionMessage;

  BackupRestoreException(this.previousExceptionMessage);

  String get message => 'Backup or restore failed: ' + previousExceptionMessage;

  @override
  String toString() {
    return message;
  }
}