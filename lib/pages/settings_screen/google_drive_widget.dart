import 'dart:async';

import 'package:diary_app/services/backup_restore.dart';
import 'package:diary_app/services/google_drive.dart';
import 'package:diary_app/ui/alert_dialog.dart';
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
  StreamSubscription _backupRestoreSubscription;
  int recordingsNotBackedUpCount = 0;
  bool isBackingUp = false;
  // Used to display the progress of the backup restore process
  int backupRestoreIndex = 0;
  int backupRestoreTotal = 0;

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

  @override
  void dispose() {
    // TODO: stop backup or move to background
    cancelBackupRestoreSubscriptions();

    super.dispose();
  }

  void toggleDriveBackup(val) async {
    if (val) {
      await drive.authenticate();
    } else {
      drive.clearAuthentication();
    }

    bool newVal = await drive.hasCredentialsStored();

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
              ListTile(
                title: Text("Recordings Needing Backup"),
                trailing: Text(recordingsNotBackedUpCount.toString()),
              ),
              OutlineButton(
                padding: EdgeInsets.only(top: 15, bottom: 15, left: 20, right: 20),
                child: Text('Initiate Backup', style: TextStyle(fontSize: 16),),
                onPressed: () => startBackup(context),
              ),
              Text("Backup Progress: $backupRestoreIndex of $backupRestoreTotal"),
              FlatButton(
                child: Text('Reset Backup History', style: TextStyle(color: Colors.red),),
                onPressed: resetBackup(googleDriveBackupEnabled, context),
              )
            ],
          ),
        );
      },
    );
  }

//  Function backupFunction(bool isBackupEnabled) {
//    if (!isBackupEnabled || isBackingUp) {
//      return null;
//    } else {
//      return startBackup;
//    }
//  }

  void startBackup(BuildContext context) {

    br.prepare();

    _backupRestoreSubscription = br.onBackupRestoreStarted.listen((e) {
      if (e != null) {
        this.setState(() {
          backupRestoreIndex = e.currentItem;
          backupRestoreTotal = e.totalItems;
        });
      }
    });

    br.backup().catchError((e) {
      print(e.message);

      // Disable cloud backup
      toggleDriveBackup(false);

      AlertDialogBox().show(context, 'Error with cloud backup', 'Please try reenabling the backup service', 'Ok');
    });
  }

  void cancelBackupRestoreSubscriptions() {
    if (_backupRestoreSubscription != null) {
      _backupRestoreSubscription.cancel();
      _backupRestoreSubscription = null;
    }
  }

  Function resetBackup(bool isBackupEnabled, BuildContext context) {
    if (!isBackupEnabled || isBackingUp) {
      return null;
    } else {
      return () async {
        if (await AlertDialogBox.showConfirm(context, 'Are you sure?',
            'This will remove the local history of your recording backups. It will not remove any files from your cloud provider.')) {
          br.resetBackupHistory();
          setState(() {
            backupRestoreIndex = 0;
            backupRestoreTotal = 0;
          });
        }
      };
    }
  }
}
