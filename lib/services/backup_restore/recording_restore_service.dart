import 'dart:io';

import 'package:diary_app/database_accessor.dart';
import 'package:diary_app/models/recording.dart';
import 'package:diary_app/services/backup_restore/backup_restore.dart';
import 'package:diary_app/services/backup_restore/file_metadata.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class RecordingRestoreService extends BackupRestore {


  // Delete file if exists
  void deleteFile(File file) {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  // Restore recordings and replace database file with items from the provided folder
  // 2. Check that folder contains database file and some recordings
  // if current folder/database are empty
  //    3. Download database file and recordings
  // TODO: else merge in files and database
  // 4. Set folder ID to be backup folder
  Future<void> restore(String folderId) async {
    String databaseFileId;
    await loadPrefs();
    // Set the backup folder so future backups will go to the correct folder
    prefs.setString(googleDriveBackupFolderIdKey, folderId);

    List<FileMetadata> databaseFileMetadata = await drive.list(parentId: folderId, name: DatabaseAccessor.dbName);

    if (databaseFileMetadata != null && databaseFileMetadata.length >= 1) {
      databaseFileId = databaseFileMetadata[0].id;
    }

    // Download database file and replace with file from Drive
//    File dbFile = File(p.join(await getLocalRecordingsFolder(), 'my.db'));
    File dbFile = File(p.join(await getLocalRecordingsFolder(), DatabaseAccessor.dbName));

    deleteFile(dbFile);

    drive.download(dbFile, databaseFileId, onDone: () async {
      print((await da.recordings()).length);
      print('opened database');

      List<Map> recordingsToRestore = await da.recordingPathAndDriveId();


      if (recordingsToRestore.length > 0) {
        recordingsToRestore.forEach((element) async {
          print('Restoring: ${element['backup_file_id']} - ${element['path']}');

          File file = File(p.join(await getLocalRecordingsFolder(), element['path'].toString()));

          deleteFile(file);

          // TODO: we must create the diary_enties directory before downloading
          // TODO: determine when download is complete so we can report to the ap
          // TODO: determine if the file is using full path or relative path so we can use relative path or just split string
          drive.download(file, element['backup_file_id']);
        });
      }
    });



    // Get list of files in the database and then download each from Drive

    // dont need to do this: Mark each file as "previously backed up" since it already exists in Drive

  }

  // Return the list of possible folders to use when restoring a backup
  Future<List<FileMetadata>> restoreFolderOptions() async {
    return await drive.list(foldersOnly: true);
  }
}
