import 'dart:io';
import 'package:diary_app/services/secure_storage.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:googleapis/abusiveexperiencereport/v1.dart' as commons;
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

String _clientId = GlobalConfiguration().getString("drive_client_id");
String _clientSecret = GlobalConfiguration().getString("drive_client_secret");

const _scopes = [ga.DriveApi.DriveFileScope];

class GoogleDrive {
  final storage = SecureStorage();
  final String defaultFolderName = "Daily Dairy Entries";

  //Get Authenticated Http Client
  Future<http.Client> getHttpClient() async {
    //Get Credentials
    var credentials = await storage.getCredentials();
    if (credentials == null) {
      //Needs user authentication
      var authClient = await clientViaUserConsent(
          ClientId(_clientId, _clientSecret), _scopes, (url) {
        //Open Url in Browser
        launch(url);
      });
      //Save Credentials
      await storage.saveCredentials(authClient.credentials.accessToken,
          authClient.credentials.refreshToken);
      return authClient;
    } else {
      print(credentials["expiry"]);
      //Already authenticated
      return authenticatedClient(
          http.Client(),
          AccessCredentials(
              AccessToken(credentials["type"], credentials["data"],
                  DateTime.tryParse(credentials["expiry"])),
              credentials["refreshToken"],
              _scopes));
    }
  }

  Future<void> authenticate() async {
    await getHttpClient();
  }

  Future<bool> isAuthenticated() async {
    var credentials = await storage.getCredentials();
    return (credentials != null);
  }

  void clearAuthentication() {
    storage.clear();
  }

  // Returns ID of folder that was created
  Future<String> createFolder() async {
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);
    ga.File fileMetadata = ga.File();
    fileMetadata.name = defaultFolderName;
    fileMetadata.mimeType = "application/vnd.google-apps.folder";

    ga.File response = await drive.files.create(fileMetadata, $fields: 'id');
    print("Created folder: ${response.id}");

    return response.id;
  }

  // Returns true if the specified folder id exists in Drive
  Future<bool> folderExists(String folderId) async {
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);

    try {
      ga.FileList folders = await drive.files.list(
          q: "mimeType='application/vnd.google-apps.folder' and trashed=false and name='$defaultFolderName'",
          $fields: "nextPageToken, files(id, name)");

      bool folderFound = false;

      List<ga.File> files = folders.files;
      for (int i = 0; i < files.length; i++) {
        if (files[i].id == folderId) {
          folderFound = true;
          break;
        }
      }

      return folderFound;

    } on commons.ApiRequestError catch (e) {
      print(e.message);
      return false;
    }
  }

  //Upload File
  Future<String> upload(File file, List<String> parents) async {
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);
    print("Uploading file");
    ga.File driveFile = ga.File();
    driveFile.name = p.basename(file.absolute.path);
    driveFile.parents = parents;

    try {
      ga.File response = await drive.files.create(driveFile,
          uploadMedia: ga.Media(file.openRead(), file.lengthSync()));
      print("Result ${response.toJson()}");
      return response.id;
    } on commons.ApiRequestError catch (e) {
      print("Failed to upload file: ${file.path}");
      print(e.toString());
      print(e.message);
      return null;
    }
  }

  Future<bool> update(File file, String fileId) async {
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);

    print("Updating file");
    ga.File driveFile = ga.File();
    driveFile.name = p.basename(file.absolute.path);

    try {
      ga.File response = await drive.files.update(driveFile, fileId,
          uploadMedia: ga.Media(file.openRead(), file.lengthSync()));
      print("Result ${response.toJson()}");
      return true;
    } on commons.ApiRequestError catch (e) {
      print("Failed to update file: ${file.path}");
      print(e.toString());
      print(e.message);
      return false;
    }
  }

  void list() async {
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);
    var response = await drive.files.list();
    print('files:');
    response.files.forEach((f) {
      print(f.name);
    });
  }
}
