import 'dart:io';
import 'package:diary_app/services/secure_storage.dart';
import 'package:global_configuration/global_configuration.dart';
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
    fileMetadata.name = "Daily Dairy Entries";
    fileMetadata.mimeType = "application/vnd.google-apps.folder";

    ga.File response = await drive.files.create(fileMetadata, $fields: 'id');
    print("Created folder: ${response.id}");

    return response.id;
  }

  //Upload File
  Future upload(File file) async {
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);
    print("Uploading file");
    ga.File driveFile = ga.File();
    driveFile.name = p.basename(file.absolute.path);
    driveFile.parents = ['19Fj2yLMTM59esTDPf7t81O_JQqEiby1s'];

    var response = await drive.files.create(driveFile,
        uploadMedia: ga.Media(file.openRead(), file.lengthSync()));

    print("Result ${response.toJson()}");
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
