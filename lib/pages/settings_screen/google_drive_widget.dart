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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    prefs = await SharedPreferences.getInstance();

    // Load whether backups are enabled
    bool _googleDriveBackupEnabled =
        (prefs.getBool(googleDriveBackupEnabledSettingsKey) ?? false);
    String _googleDriveBackupFolderId =
        prefs.getString(googleBackupFolderIdSettingsKey);

    this.setState(() {
      googleDriveBackupEnabled = _googleDriveBackupEnabled;
      googleDriveBackupFolderId = _googleDriveBackupFolderId;
    });
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
          )
        ],
      ),
    );
  }
}
