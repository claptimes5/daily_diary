import 'dart:async';
import 'dart:io';
import 'package:diary_app/services/backup_restore/file_metadata.dart';
import 'package:googleapis/abusiveexperiencereport/v1.dart' as commons;
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'package:google_sign_in/google_sign_in.dart'
    show GoogleSignIn, GoogleSignInAccount;

import 'package:http/io_client.dart';
import 'package:http/http.dart';

const _scopes = [ga.DriveApi.DriveFileScope];

GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: _scopes
);

class GoogleDrive {
  final String defaultFolderName = "Daily Dairy Entries";

  Future<http.Client> getHttpClient() async {

    GoogleSignInAccount _account = _googleSignIn.currentUser;


    if (_account == null) {
      _account = await _googleSignIn.signInSilently();
    }

    if (_account == null) {
      _account = await _googleSignIn.signIn();
    }

    final authHeaders = await _googleSignIn.currentUser.authHeaders;

    return GoogleHttpClient(authHeaders);
  }

  Future<void> authenticate() async {
    await getHttpClient();
  }

  Future<bool> hasCredentialsStored() async {

    return await _googleSignIn.isSignedIn();
  }

  void clearAuthentication() {
    _googleSignIn.signOut();
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

  // Returns all folders that this app has permissions to
//  Future<Map<String, String>> folderList() async {
//    var client = await getHttpClient();
//    var drive = ga.DriveApi(client);
//    Map<String,String> folderList = Map();
//
//    try {
//      ga.FileList folders = await drive.files.list(
//          q: "mimeType='application/vnd.google-apps.folder' and trashed=false",
//          $fields: "nextPageToken, files(id, name)");
//
//      folders.files.forEach((element) {
//        folderList[element.id] = element.name;
//      });
//
//      return folderList;
//    } on commons.ApiRequestError catch (e) {
//      print(e.message);
//      return null;
//    }
//  }

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

      return response.id;
    } on commons.ApiRequestError catch (e) {
      print("Failed to upload file: ${file.path}");
      print(e.toString());
      print(e.message);
      return null;
    }
  }

  // Download file by given ID
  Future<Stream> download(File file, String driveId, {Function onDone}) async {
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);

    ga.Media downloadedFile = await drive.files.get(driveId, downloadOptions:  ga.DownloadOptions.FullMedia);
    print('Writing file');
//    downloadedFile.stream.
//    file.writeAsBytes(await downloadedFile.stream.toList());
//    downloadedFile.stream.listen((event) {
//        file.writeAsBytes(event);
//    }).asFuture();

    List<int> dataStore = [];
    downloadedFile.stream.listen((data) {
//      print("DataReceived: ${data.length}");
      dataStore.insertAll(dataStore.length, data);
    }, onDone: () async {
      await file.writeAsBytes(dataStore); //Write to that file from the datastore you created from the Media stream
      print('File written');
      if (onDone != null) {
        onDone();
      }
    }, onError: (error) {
      print("Error downloading file");
    });

    return downloadedFile.stream;
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

  // Get all files that have not been trashed
  // [name]
  // [parentId] Include optional parent ID to scope list of files that exist
  // inside specified folder
  // [foldersOnly] Set to true and this will only return folders
  Future<List<FileMetadata>> list({String name, String parentId, bool foldersOnly = false}) async {
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);
    String queryString = 'trashed=false';

    if (name != null) {
      queryString += " and name = '$name'";
    }

    if (parentId != null) {
      queryString += " and parents in '$parentId'";
    }

    if (foldersOnly) {
      queryString += " and mimeType='application/vnd.google-apps.folder'";
    }

    try {
      print('query: $queryString');
      var response = await drive.files
          .list(q: queryString, $fields: "nextPageToken, files(id, name)");

      print('files returned: ${response.files.length}');

      return response.files.map((element) {
        return FileMetadata(element.name, element.id);
      }).toList();
    } on commons.ApiRequestError catch (e) {
      print(e.toString());
      return null;
    }
  }
}

class GoogleHttpClient extends IOClient {
  Map<String, String> _headers;

  GoogleHttpClient(this._headers) : super();

  @override
  Future<IOStreamedResponse> send(BaseRequest request) =>
      super.send(request..headers.addAll(_headers));

  @override
  Future<Response> head(Object url, {Map<String, String> headers}) =>
      super.head(url, headers: headers..addAll(_headers));

}