import 'dart:async';

import 'package:diary_app/services/backup_restore/file_metadata.dart';
import 'package:diary_app/services/backup_restore/recording_backup_service.dart';
import 'package:diary_app/services/backup_restore/recording_restore_service.dart';
import 'package:diary_app/services/google_drive.dart';
import 'package:diary_app/ui/alert_dialog_box.dart';
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
  RecordingBackupService rb = RecordingBackupService();
  RecordingRestoreService restoreService = RecordingRestoreService();
  StreamSubscription _backupRestoreSubscription;
  int recordingsNotBackedUpCount = 0;
  bool isBackingUp = false;
  // Used to display the progress of the backup restore process
  int backupRestoreIndex = 0;
  int backupRestoreTotal = 0;
  bool isRestoreFolderSelectOpen = false;
  String restoreFolderId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<bool> _loadSettings() async {
    prefs = await SharedPreferences.getInstance();
    recordingsNotBackedUpCount = await rb.recordingsNotBackedUpCount();
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

        if (snapshot.hasData) {
          print('TODO REMOVE: hasData setting prefs');
          // Load whether backups are enabled
          googleDriveBackupEnabled =
          (prefs.getBool(googleDriveBackupEnabledSettingsKey) ?? false);
          googleDriveBackupFolderId =
          prefs.getString(googleBackupFolderIdSettingsKey);
        }

        List<Widget> cardChildren = [
          ListTile(
            leading: Icon(
              Icons.backup,
              color: Colors.black26,
            ),
            title: Text("Google Drive Backup"),
            trailing: CommonSwitch(
              defValue: googleDriveBackupEnabled,
              onChanged: toggleDriveBackup,
            ),
          ),
        ];

        if (googleDriveBackupEnabled) {
          cardChildren.addAll([
            ListTile(
              title: Text("Recordings Needing Backup"),
              trailing: Text(recordingsNotBackedUpCount.toString()),
            ),
            OutlineButton(
              padding:
              EdgeInsets.only(top: 15, bottom: 15, left: 20, right: 20),
              focusColor: (isBackingUp ? Colors.green : Colors.grey),
              child: Text(
                'Initiate Backup',
                style: TextStyle(fontSize: 16),
              ),
              onPressed: onStartBackupPressed(context),
            ),
          ]);

          if (isBackingUp) {
            cardChildren.add(
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                    "Backup Progress: $backupRestoreIndex of $backupRestoreTotal"),
              ),
            );
          }

          cardChildren.add(FlatButton(
            padding: EdgeInsets.only(top: 15),
            child: Text(
              'Reset Backup History',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: resetBackup(googleDriveBackupEnabled, context),
          ));


          // Show restore option if restore folder hasn't been selected
          if (!isRestoreFolderSelectOpen){
            cardChildren.add(
                FlatButton(
                  padding: EdgeInsets.only(top: 15),
                  child: Text(
                    'Restore From Backup',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: openRestoreFolderSelectBox,
                )
            );
          }

          if (isRestoreFolderSelectOpen) {
            cardChildren.add(folderOptions());
          }

          if (restoreFolderId != null) {
            cardChildren.add(initiateRestoreButton(context));
          }
        }

        return Card(
          color: Colors.white,
          elevation: 2.0,
          child: Column(
            children: cardChildren,
          ),
        );
      },
    );
  }

  Function onStartBackupPressed(context) {
    if (isBackingUp) {
      return null;
    } else {
      return () {
        startBackup(context);
      };
    }
  }

  void startBackup(BuildContext context) {

    rb.prepare();

    _backupRestoreSubscription = rb.onBackupRestoreStarted.listen((e) {
      if (e != null) {
        this.setState(() {
          backupRestoreIndex = e.currentItem;
          backupRestoreTotal = e.totalItems;

          if (backupRestoreTotal == backupRestoreIndex) {
            isBackingUp = false;
          }
        });
      }
    });

    setState(() {
      isBackingUp = true;
    });

    rb.backup().catchError((e) {
      print('ERROR starting file backup');
      print(e?.message);

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
    if (isBackingUp) {
      return null;
    } else {
      return () async {
        if (await AlertDialogBox.showConfirm(context, 'Are you sure?',
            'This will remove the local history of your recording backups. It will not remove any files from your cloud provider.')) {
          rb.resetBackupHistory();
          setState(() {
            backupRestoreIndex = 0;
            backupRestoreTotal = 0;
          });
        }
      };
    }
  }

  openRestoreFolderSelectBox() {
    setState(() {
      isRestoreFolderSelectOpen = true;
    });
  }

  Widget initiateRestoreButton(context) {
    return RaisedButton(
      onPressed: () async {
        if (await AlertDialogBox.showConfirm(context, 'Restore Files', 'Are you sure? This will delete any current recordings on this device.')) {
          restoreFilesFromBackup();
        }
      },
      child: Text('Initiate Restore'),
    );
  }

  Future<void> restoreFilesFromBackup() async {
    restoreService.restore(restoreFolderId);
  }

  Future<List<FileMetadata>> getRetoreFolderOptions() {
    return restoreService.restoreFolderOptions();
  }

  void setRestoreFolder(String folderId) {
    print(folderId);
    setState(() {
      isRestoreFolderSelectOpen = false;
      restoreFolderId = folderId;
    });
  }

  Widget folderOptions() {
    return FutureBuilder(
      future: getRetoreFolderOptions(),
      builder: (context, snapshot) {
        List<FileMetadata> folderList = [];
        bool showLoading = false;
        String textDisplay = 'Select a folder to restore from';

        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.active) {
          showLoading = true;
          textDisplay = 'Loading Folders';
        } else if (snapshot.hasError) {
          textDisplay = 'Error Loading Folders';
        } else {
          folderList = snapshot.data;
        }

        return Container(
          color: Colors.white.withOpacity(0.8),
          child: Column(
            children: [
              Text(textDisplay),
              ListView.separated(
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  var item = folderList[index];
//          final formatter = DateFormat('hh:mm EEE, MMM d, yyyy');

                  return Card(
                    elevation: 0.0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 1.0, color: Colors.blue.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    color: Colors.white.withOpacity(0.8),
                    child: FlatButton(
                        onPressed: () {
                          setRestoreFolder(item.id);
                        },
                        child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(height: 4.0),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
//                            formatter.format(item.createdDate),
                                    item.id,
                                    style: TextStyle(
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return SizedBox(height: 8.0);
                },
                itemCount: folderList.length,
                padding: const EdgeInsets.all(8.0),
              ),
            ],
          )
        );

      },
    );

  }
}
