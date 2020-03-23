import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:diary_app/database_accessor.dart';
import 'package:diary_app/models/recording.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/scheduler.dart';
import 'dart:io' show Platform;

class RecordingScreen extends StatefulWidget {
  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool _isRecording = false;
  bool _isPlaying = false;
  final int _maxRecordingLength = 15000;
  String _path;
  FlutterSound flutterSound;
  StreamSubscription _playerSubscription;
  StreamSubscription _recorderSubscription;
  String recorderText = '15:00 seconds';
  String playerText = '15';
  String diaryEntryDir = 'diary_entries';
  bool _fileSaved = false;

  @override
  Widget build(BuildContext context) {
    return _buildPage();
  }

  @override
  void initState() {
    super.initState();
    flutterSound = new FlutterSound();
    flutterSound.setSubscriptionDuration(0.01);
    flutterSound.setDbPeakLevelUpdate(0.8);
    flutterSound.setDbLevelEnabled(true);
//    initializeDateFormatting();
  }

  Future<void> alertDialog(String title, String text, String buttonText) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(text),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(buttonText),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void requestPermissions() async {
    Map<PermissionGroup, PermissionStatus> permissions =
        await PermissionHandler().requestPermissions(
            [PermissionGroup.storage, PermissionGroup.microphone]);
  }

  Future<bool> checkPermissions() async {
    PermissionStatus permissionStorage = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);
    PermissionStatus permissionMicrophone = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.microphone);

    PermissionStatus permissionGranted = PermissionStatus.granted;

    if (permissionStorage.value != permissionGranted.value ||
        permissionMicrophone.value != permissionGranted.value) {
      alertDialog('Microphone and Storage permissions required',
          'Please grant permissions so your voice can be recorded.', 'OK');
      requestPermissions();

      return false;
    } else {
      return true;
    }
  }

  @override
  void dispose() {
    flutterSound.stopPlayer().catchError((e, trace) {
      print('Stop player failed because it was not running');
    }, test: (e) => e is PlayerRunningException);
    flutterSound.stopRecorder().catchError((e, trace) {
      print('Stop recorder failed because it was not running');
    }, test: (e) => e is RecorderStoppedException);
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      if (_isRecording) {
        _stopRecording();
        setState(() {
          _isRecording = false;
        });
      } else {
        _startRecording();
      }
    });
  }

  void _startRecording() async {
    checkPermissions().then((permissionsGranted) {
      if (!permissionsGranted) {
        return;
      }
    });

    try {
      String path = await flutterSound.startRecorder(
        codec: t_CODEC.CODEC_AAC,
        sampleRate: 48000,
        bitRate: 128000,
        numChannels: 1,
      );
      print('startRecorder: $path');

      _recorderSubscription = flutterSound.onRecorderStateChanged.listen((e) {
        int timeRemaining = _maxRecordingLength - e.currentPosition.toInt();
        if (timeRemaining < 0)
          timeRemaining = 0;

        DateTime date = new DateTime.fromMillisecondsSinceEpoch(
            timeRemaining,
            isUtc: true);
        String txt = DateFormat('ss:SS', 'en_US').format(date);

        if (e.currentPosition.toInt() >= _maxRecordingLength) {
          print(_maxRecordingLength);
          print(e.currentPosition.toInt());
         _stopRecording();
        }

        this.setState(() {
          this.recorderText = '${txt.substring(0, 5)} seconds';
        });
      });

      setState(() {
        _isRecording = true;
        this._path = path;
        this._fileSaved = false;
      });
    } catch (err) {
      print('startRecorder error: $err');
      setState(() {
        this._isRecording = false;
      });
    }
  }

  void _stopRecording() async {
    try {
      String result = await flutterSound.stopRecorder();
      print('stopRecorder: $result');

      if (_recorderSubscription != null) {
        _recorderSubscription.cancel();
        _recorderSubscription = null;
      }
    } catch (err) {
      print('stopRecorder error: $err');
    }
    this.setState(() {
      this._isRecording = false;
    });
  }

  void startPlayer() async {
    try {
      String path;
      if (await fileExists(_path))
        path = await flutterSound.startPlayer(this._path);

      if (path == null) {
        print('Error starting player');
        return;
      }
      print('startPlayer: $path');
      await flutterSound.setVolume(0.4);

      _playerSubscription = flutterSound.onPlayerStateChanged.listen((e) {
        if (e != null) {
          if (flutterSound.audioState == t_AUDIO_STATE.IS_STOPPED) {
            setState(() {
              this._isPlaying = false;
            });
          }

          DateTime date = new DateTime.fromMillisecondsSinceEpoch(
              e.currentPosition.toInt(),
              isUtc: true);
//          String txt = DateFormat('mm:ss:SS', 'en_GB').format(date);

        }
      });

      this.setState(() {
        this._isPlaying = true;
//            this.playerText = txt.substring(0, 8);
      });
    } catch (err) {
      print('error: $err');
    }
  }

  void stopPlayer() async {
    try {
      String result = await flutterSound.stopPlayer();
      print('stopPlayer: $result');
      if (_playerSubscription != null) {
        _playerSubscription.cancel();
        _playerSubscription = null;
      }
//      sliderCurrentPosition = 0.0;
    } catch (err) {
      print('error: $err');
    }
    this.setState(() {
      this._isPlaying = false;
    });
  }

  void saveRecording() async {
    if (_fileSaved) {
      return;
    }
    try {
      //TODO: make on subdirectory per month
      final tmpRecording = File(this._path);
      Directory appDocDir;

      // Create directory for files
      if (Platform.isAndroid) {
        appDocDir = await getExternalStorageDirectory();
      } else {
        appDocDir = await getApplicationDocumentsDirectory();
      }

      String appDocPath = appDocDir.path;

      String fullDirPath = p.join(appDocPath, diaryEntryDir);
//    String fullDirPath = diaryEntryDir;
      String fileName = 'daily_diary_' + DateTime.now().toIso8601String() + '.aac';
      String fullFilePath = p.join(appDocPath, diaryEntryDir, fileName);
//    String fullFilePath =
//        p.join(diaryEntryDir, DateTime.now().toIso8601String());

      Directory dir = await Directory(fullDirPath).create(recursive: true);
      final exists = await dir.exists();

      // Copy temp file to new directory

      final file = await tmpRecording.copy(fullFilePath);

      final DatabaseAccessor da = DatabaseAccessor();
      da.insertModel(new Recording(time: DateTime.now(), path: fullFilePath));

      tmpRecording.deleteSync();
      setState(() {
        this._path = null;
        this._isPlaying = false;
        this._fileSaved = true;
        this.recorderText = '15:00 seconds';
      });
    } catch (e) {
      print('did not save file');
      print(e.toString());
      alertDialog('Save Failed', 'Please try again', 'OK');
    }
  }

  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  Widget _buildPage() {
    return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
//          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            titleSection(),
            recordSection(),
            playSection(),
            saveSection()
          ],
        ));
  }

  String currentDate() {
    final d = DateTime.now();
    return '${d.month}/${d.day}/${d.year}';
  }

  // Indicates whether the audio journal for today has been completed
  Future<bool> isEntryComplete() async {
    DateTime endTime = DateTime.now();
    DateTime startTime = DateTime(endTime.year,
        endTime.month,
        endTime.day);
    final DatabaseAccessor da = DatabaseAccessor();

    List<Recording> recordings = await da.recordings(startTime: startTime, endTime: endTime);

    return recordings.length == 1;
  }

  Widget titleSection() {
    String recordCompleteText = 'Incomplete';
    Color recordCompleteColor = Colors.redAccent;

    return FutureBuilder(
      future: isEntryComplete(),
      builder: (context, snapshot) {
        if (snapshot.hasData && !snapshot.hasError && snapshot.data) {
          recordCompleteText = 'Complete';
          recordCompleteColor = Colors.lightGreen;
        }

        return Container(
            padding: const EdgeInsets.all(4),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                [
                  Text(
                      'Journal Entry for ${currentDate()}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22
                      )),
                  Text(recordCompleteText,
                      style: TextStyle(
                          color: recordCompleteColor,
//                  fontWeight: FontWeight.bold,
                          fontSize: 20
                      ))
                ])
        );
      },
    );
  }

  Widget recordSection() {
    Widget statusText;
    Widget recordingButton;

    if (_fileSaved) {
      statusText = Text('Saved');
    } else if (_isRecording) {
      statusText = Text('Recording');
    } else {
      statusText = Text('Ready to record');
    }

    if (_isRecording) {
      recordingButton = Icon(Icons.stop, color: Colors.black, size: 140);
    } else if (_path != null) {
      recordingButton = Icon(Icons.undo, color: Colors.black, size: 140);
    } else {
      recordingButton = Icon(Icons.fiber_manual_record,
          color: Colors.red, size: 140);
    }

    return Container(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          IconButton(
            icon: recordingButton,
            onPressed: _toggleRecording,
            iconSize: 140,
          ),
          Text(recorderText),
          statusText,
        ]));
  }

  Widget playSection() {
    Function onpressed;
    if (_isRecording || _path == null) {
      onpressed = null;
    } else if (_isPlaying) {
      onpressed = stopPlayer;
    } else {
      onpressed = startPlayer;
    }

    return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
            child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              IconButton(
                  icon: (_isPlaying
                      ? Icon(Icons.stop, size: 70)
                      : Icon(Icons.play_arrow, size: 70, color: (onpressed != null ? Colors.green : Colors.grey))),
                  onPressed: onpressed,
                  iconSize: 70),
            ])));
  }

  Widget saveSection() {
    Function onpressed;
    if (_isRecording || _path == null) {
      onpressed = null;
    } else {
      onpressed = saveRecording;
    }

    return RaisedButton(
        onPressed: onpressed,
//      padding: const EdgeInsets.all(32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Save', style: TextStyle(fontSize: 30.0),)
          ],
        )
      );
  }
}
