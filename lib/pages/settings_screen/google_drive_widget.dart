import 'package:diary_app/services/backup_restore.dart';
import 'package:diary_app/services/google_drive.dart';
import 'package:diary_app/ui/common_switch.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleDriveWidget extends StatefulWidget {
//  final SharedPreferences prefs;

//  GoogleDriveWidget ({ Key key, this.prefs }): super(key: key);

  @override
  GoogleDriveWidgetState createState() => GoogleDriveWidgetState();
}

class GoogleDriveWidgetState extends State<GoogleDriveWidget> {
  final drive = GoogleDrive();
  bool googleDriveBackupEnabled = false;
  String googleDriveBackupFolderId;
  SharedPreferences prefs;
  final String googleDriveBackupEnabledSettingsKey =
      'google_drive_backup_enabled';
  final String googleBackupFolderIdSettingsKey =
      'google_drive_backup_folder_id';
  BackupRestore br = BackupRestore();
  int recordingsNotBackedUpCount = 0;
  bool isBackingUp = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<bool> _loadSettings() async {
    prefs = await SharedPreferences.getInstance();
    recordingsNotBackedUpCount = await br.recordingsNotBackedUpCount();
  return true;


//    this.setState(() {
//      googleDriveBackupEnabled = _googleDriveBackupEnabled;
//      googleDriveBackupFolderId = _googleDriveBackupFolderId;
//    });
  }

  void toggleDriveBackup(val) async {
    if (val) {
      await drive.authenticate();
    } else {
      drive.clearAuthentication();
    }

    bool newVal = await drive.isAuthenticated();

    prefs
        .setBool(googleDriveBackupEnabledSettingsKey, newVal)
        .then((bool success) {
      if (success) {
        setState(() {
          googleDriveBackupEnabled = newVal;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadSettings(),
      builder: (BuildContext context, snapshot) {
        print(snapshot.hasData);
        if (snapshot.hasData) {
          print('TODO REMOVE: hasData setting prefs');
          // Load whether backups are enabled
          googleDriveBackupEnabled =
          (prefs.getBool(googleDriveBackupEnabledSettingsKey) ?? false);
          googleDriveBackupFolderId =
          prefs.getString(googleBackupFolderIdSettingsKey);
        }

        return Card(
          color: Colors.white,
          elevation: 2.0,
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.backup,
                  color: Colors.black26,
                ),
                title: Text("Drive Backup Enabled"),
                trailing: CommonSwitch(
                  defValue: googleDriveBackupEnabled,
                  onChanged: toggleDriveBackup,
                ),
              ),
              Text("Items to backup: $recordingsNotBackedUpCount"),
              FlatButton(
                child: Text('Initiate Backup'),
                onPressed: startBackup(googleDriveBackupEnabled),
              ),
              FlatButton(
                child: Text('Reset Backup'),
                onPressed: resetBackup(googleDriveBackupEnabled),
              )
            ],
          ),
        );
      },
    );
  }


  Function startBackup(bool isBackupEnabled) {
    if (!isBackupEnabled || isBackingUp) {
      return null;
    } else {
      return br.backup;
    }
  }

  Function resetBackup(bool isBackupEnabled) {
    if (!isBackupEnabled || isBackingUp) {
      return null;
    } else {
      return br.resetBackupHistory;
    }
  }
}
