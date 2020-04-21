import 'package:diary_app/pages/recording_screen/calendar_section.dart';
import 'package:diary_app/pages/recording_screen/record_widget.dart';
import 'package:diary_app/pages/recording_screen/title_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flauto.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/flutter_sound_recorder.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:diary_app/database_accessor.dart';
import 'package:diary_app/models/recording.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:table_calendar/table_calendar.dart';
import 'package:diary_app/ui/alert_dialog.dart';

class RecordingScreen extends StatefulWidget {
  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool _isRecording = false;
  bool _recordingLimitReached = false;
  int _maxRecordingLength = 24000;
  String _path;
  FlutterSoundRecorder flutterSoundRecorder;
  StreamSubscription _recorderSubscription;
  String recorderText = '24:00 seconds';
  String diaryEntryDir = 'diary_entries';
  bool _fileSaved = false;
  CalendarController _calendarController;
  Map<DateTime, List> _events = {};
  SharedPreferences prefs;
  final recordingLengthKey = 'recording_lehgth';
  int _currentPosition = 0;

  @override
  Widget build(BuildContext context) {
    return _buildPage();
  }

  @override
  void initState() {
    super.initState();
    initRecorder();

    populatePreviousRecordings();

    _calendarController = CalendarController();
    _loadSettingsData();
  }

  void cancelRecorderSubscriptions() {
    if (_recorderSubscription != null) {
      _recorderSubscription.cancel();
      _recorderSubscription = null;
    }
  }

  void initRecorder() {
    flutterSoundRecorder = FlutterSoundRecorder();
    flutterSoundRecorder.setSubscriptionDuration(0.01);
  }

  t_AUDIO_STATE get audioState {
    if (flutterSoundRecorder != null) {
      if (flutterSoundRecorder.isPaused) return t_AUDIO_STATE.IS_RECORDING_PAUSED;
      if (flutterSoundRecorder.isRecording) return t_AUDIO_STATE.IS_RECORDING;
    }
    return t_AUDIO_STATE.IS_STOPPED;
  }

  _loadSettingsData() async {
    prefs = await SharedPreferences.getInstance();

    int _length = prefs.getInt(recordingLengthKey);

    if (_length != null) {
      setState(() {
        // Recording length is stored in seconds but the recorder uses milliseconds
        _maxRecordingLength = _length * 1000;
      });
    }
  }

  void requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.storage,
    ].request();

    if (await Permission.storage.isPermanentlyDenied || await Permission.microphone.isPermanentlyDenied) {
      // The user opted to never again see the permission request dialog for this
      // app. The only way to change the permission's status now is to let the
      // user manually enable it in the system settings.
      openAppSettings();
    }
  }

  Future<bool> checkPermissions() async {
    var microphoneStatus = await Permission.microphone.status;
    var storageStatus = await Permission.storage.status;

    if (microphoneStatus.isGranted && storageStatus.isGranted) {
      return true;
    } else {
      await AlertDialogBox().show(context,'Microphone and Storage permissions required',
          'Please grant permissions so your voice can be recorded.', 'OK');
      requestPermissions();

      return false;
    }
  }

  Future<void> releaseFlauto() async {
    try {
      await flutterSoundRecorder.release();
    } catch (e) {
      print('Released unsuccessful');
      print(e);
    }
  }

  @override
  void dispose() {
    flutterSoundRecorder.stopRecorder();

    cancelRecorderSubscriptions();
    releaseFlauto();

    _calendarController.dispose();

    super.dispose();
  }

  void toggleRecording() async {
    if (audioState == t_AUDIO_STATE.IS_RECORDING) {
      await flutterSoundRecorder.pauseRecorder();

      setState(() {
        _isRecording = false;
      });
    } else {
      _startRecording();
    }
  }

  void _startRecording() async {
    checkPermissions().then((permissionsGranted) {
      if (!permissionsGranted) {
        return;
      }
    });

    try {
      if (flutterSoundRecorder.isPaused) {
        await flutterSoundRecorder.resumeRecorder();

        setState(() {
          _isRecording = true;
        });
      } else {
        String path = await flutterSoundRecorder.startRecorder(
          codec: t_CODEC.CODEC_AAC,
          sampleRate: 48000,
          bitRate: 128000,
          numChannels: 1,
        );

        _recorderSubscription = flutterSoundRecorder.onRecorderStateChanged.listen((e) {

          if (e.currentPosition.toInt() >= _maxRecordingLength) {
            _stopRecording();

            this.setState(() {
              this._recordingLimitReached = true;
            });
          }

          this.setState(() {
            this._currentPosition = e.currentPosition.toInt();
          });
        });

        setState(() {
          _isRecording = true;
          this._path = path;
          this._fileSaved = false;
        });
      }
    } catch (err) {
      print('startRecorder error: $err');
      setState(() {
        this._isRecording = false;
      });
    }
  }

  void _stopRecording() async {
    try {
      String result = await flutterSoundRecorder.stopRecorder();
      print('stopRecorder: $result');

      cancelRecorderSubscriptions();
    } catch (err) {
      print('stopRecorder error: $err');
    }
    this.setState(() {
      this._isRecording = false;
    });
  }

  void saveRecording() async {
    if (_fileSaved) {
      return;
    }
    try {
      if (audioState == t_AUDIO_STATE.IS_RECORDING_PAUSED) {
        _stopRecording();
      }

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
      String fileName = 'daily_diary_' + DateTime.now().toIso8601String() + '.aac';
      String relativeFilePath = p.join(diaryEntryDir, fileName);
      String fullFilePath = p.join(appDocPath, diaryEntryDir, fileName);

      if (!(await Directory(fullDirPath).exists())) {
        await Directory(fullDirPath).create(recursive: true);
      }

      // Copy temp file to new directory
      await tmpRecording.copy(fullFilePath);

      final DatabaseAccessor da = DatabaseAccessor();
      da.insertModel(new Recording(time: DateTime.now(), path: relativeFilePath));

      tmpRecording.deleteSync();

      // Retrieve previous recordings so they can be displayed in the calendar widget
      populatePreviousRecordings();

      resetRecording();
    } catch (e) {
      print('did not save file');
      print(e.toString());
      AlertDialogBox().show(context,'Save Failed', 'Please try again', 'OK');
    }
  }

  Widget _buildPage() {
    return FutureBuilder(
        future: isEntryComplete(),
        builder: (context, snapshot) {
          bool _isEntryComplete = false;

          // snapshot.data returns true if entry is complete for today
          if (snapshot.hasData && !snapshot.hasError && snapshot.data) {
            _isEntryComplete = snapshot.data;
          }

          return Container(
              padding: const EdgeInsets.only(
                left: 0.0,
                top: 0.0,
                right: 0.0,
                bottom: 10.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TitleSection(isTodaysEntryComplete: _isEntryComplete),
                  CalendarSection(events: this._events,
                      isTodaysEntryComplete: _isEntryComplete,
                      calendarController: _calendarController),
                  RecordWidget(
                    recordingPath: this._path,
                    isRecording: this._isRecording,
                    onResetRecording: resetRecording,
//                    recorderText: recorderText,
                    currentPosition: this._currentPosition,
                    maxRecordingLength: this._maxRecordingLength,
                    fileSaved: this._fileSaved,
                    onToggleRecording: toggleRecording,
                    recordingLimitReached: this._recordingLimitReached,
                  ),
                  saveSection()
                ],
              ));
        });
  }

  // Indicates whether the audio journal for today has been completed
  Future<bool> isEntryComplete() async {
    final now = DateTime.now();
    final tomorrow = now.add(Duration(days: 1));
    final endTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final startTime = DateTime(now.year,
        now.month,
        now.day);
    final DatabaseAccessor da = DatabaseAccessor();

    List<Recording> recordings = await da.recordings(startTime: startTime, endTime: endTime);

    return recordings.length >= 1;
  }

  Future<void> populatePreviousRecordings() async {
    DateTime endTime = DateTime.now();
    DateTime startTime = DateTime(endTime.year,
        endTime.month,
        endTime.day).subtract(Duration(days: 7));
    final DatabaseAccessor da = DatabaseAccessor();

    List<Recording> recordings = await da.recordings(startTime: startTime, endTime: endTime);

    Map<DateTime, List> events = {};

    recordings.forEach((r) {
      events[r.time] = ['true'];
    });

    setState(() {
      _events = events;
    });
  }

  Future<void> resetRecording() async {
    _stopRecording();
    cancelRecorderSubscriptions();

    setState(() {
      this._recordingLimitReached = false;
      this._path = null;
      this._fileSaved = false;
      this._isRecording = false;
      this._currentPosition = 0;
    });
  }

  Widget saveSection() {
    Function onpressed;
    if (_isRecording || _path == null) {
      onpressed = null;
    } else {
      onpressed = saveRecording;
    }

    return Container(
        margin: EdgeInsets.only(left: 30, right: 30),
        child: RaisedButton(
            onPressed: onpressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check, size: 30),
                Text('Save', style: TextStyle(fontSize: 30.0),)
              ],
            )
        )
    );
  }
}
