import 'package:flutter/material.dart';
import 'package:flutter_sound/flauto.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/flutter_sound_player.dart';
import 'package:flutter_sound/flutter_sound_recorder.dart';
import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart' show DateFormat;
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
  bool _isPlaying = false;
  bool _recordingLimitReached = false;
  int _maxRecordingLength = 24000;
  String _path;
  FlutterSoundRecorder flutterSoundRecorder;
  FlutterSoundPlayer flutterSoundPlayer;
  StreamSubscription _playerSubscription;
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
    initPlayerAndRecorder();

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

  void cancelPlayerSubscriptions() {
    if (_playerSubscription != null) {
      _playerSubscription.cancel();
      _playerSubscription = null;
    }
  }

  void initPlayerAndRecorder() {
    flutterSoundRecorder = FlutterSoundRecorder();
    flutterSoundPlayer = FlutterSoundPlayer();
    flutterSoundRecorder.setSubscriptionDuration(0.01);
    flutterSoundPlayer.setSubscriptionDuration(0.01);
  }

  t_AUDIO_STATE get audioState {
    if (flutterSoundPlayer != null) {
      if (flutterSoundPlayer.isPlaying) return t_AUDIO_STATE.IS_PLAYING;
      if (flutterSoundPlayer.isPaused) return t_AUDIO_STATE.IS_PAUSED;
    }
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
        recorderText = _timeRemaining(0);
      });
    }
  }

  Widget _buildTableCalendar() {
    return FutureBuilder(
        future: isEntryComplete(),
        builder: (context, snapshot) {
          Color todayColor = Colors.red[300];

          // snapshot.data returns true if entry is complete for today
          if (snapshot.hasData && !snapshot.hasError && snapshot.data) {
            todayColor = Colors.green;
          }

          final startingDay = DateTime.now().subtract(Duration(days: 6));
          final endDay = DateTime.now();

          return TableCalendar(
            calendarController: _calendarController,
            events: _events,
//      holidays: _holidays,
            initialCalendarFormat: CalendarFormat.week,
            startingDayOfWeek: StartingDayOfWeek.values[startingDay.weekday -1],
            startDay: startingDay,
            endDay: endDay,
            calendarStyle: CalendarStyle(
                selectedColor: Colors.deepOrange[400],
                todayColor: todayColor,
                markersColor: Colors.green[700],
                outsideDaysVisible: false,
                highlightSelected: false,
                weekendStyle: null,
                outsideWeekendStyle: null,
            ),
            headerVisible: false,
            availableGestures: AvailableGestures.none,
            daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: const Color(0xFF616161)),
                weekendStyle: TextStyle(color: const Color(0xFF616161))),
            headerStyle: HeaderStyle(
              centerHeaderTitle: true,
              formatButtonVisible: false,
              headerPadding: EdgeInsets.symmetric(vertical: 2.0),
//        formatButtonTextStyle: TextStyle().copyWith(color: Colors.white, fontSize: 15.0),
//        formatButtonDecoration: BoxDecoration(
//          color: Colors.deepOrange[400],
//          borderRadius: BorderRadius.circular(16.0),
//        ),
            ),
          );
        }
    );
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
      await flutterSoundPlayer.release();
      await flutterSoundRecorder.release();
    } catch (e) {
      print('Released unsuccessful');
      print(e);
    }
  }

  @override
  void dispose() {
    flutterSoundPlayer.stopPlayer();
    flutterSoundRecorder.stopRecorder();

    cancelRecorderSubscriptions();
    cancelPlayerSubscriptions();
    releaseFlauto();

    _calendarController.dispose();

    super.dispose();
  }

  void _toggleRecording() async {
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
            this.recorderText = _timeRemaining(e.currentPosition.toInt());
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

  String _timeRemaining(currentPosition) {
    int timeRemaining = _maxRecordingLength - currentPosition;
    if (timeRemaining < 0)
      timeRemaining = 0;

    DateTime date = new DateTime.fromMillisecondsSinceEpoch(
        timeRemaining,
        isUtc: true);
    String format;

    if (_maxRecordingLength >= 60000) {
      format = 'mm:ss:SS';
    } else {
      format = 'ss:SS';
    }
    String txt = DateFormat(format, 'en_US').format(date);

    return 'Time Remaining: ${txt.substring(0, format.length)}';
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

  void startPlayer() async {
    try {
      String path;
      if (await fileExists(_path))
        path = await flutterSoundPlayer.startPlayer(this._path);

      if (path == null) {
        print('Error starting player');
        return;
      }
      print('startPlayer: $path');

      _playerSubscription = flutterSoundPlayer.onPlayerStateChanged.listen((e) {
        if (e != null) {
          if (audioState == t_AUDIO_STATE.IS_STOPPED || audioState == t_AUDIO_STATE.IS_RECORDING_PAUSED) {
            cancelPlayerSubscriptions();
            flutterSoundPlayer.release();
            setState(() {
              this._isPlaying = false;
            });
          }
        }
      });

      this.setState(() {
        this._isPlaying = true;
      });
    } catch (err) {
      print('error: $err');
      _stopRecording();
    }
  }

  Future<void> stopPlayer() async {
    try {
      String result = await flutterSoundPlayer.stopPlayer();
      print('stopPlayer: $result');
      cancelPlayerSubscriptions();

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

      setState(() {
        this._path = null;
        this._isPlaying = false;
        this._fileSaved = true;
        this.recorderText = _timeRemaining(0);
      });
    } catch (e) {
      print('did not save file');
      print(e.toString());
      AlertDialogBox().show(context,'Save Failed', 'Please try again', 'OK');
    }
  }

  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  Widget _buildPage() {
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
            titleSection(),
            calendarSection(),
            playRecordSection(),
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

  Widget calendarSection() {
    Map daysCounted = {};

    // Count the number of unique events per day
    _events.keys.forEach((e) {
      daysCounted[e.day] = 1;
    });

    return Column(children: [
      _buildTableCalendar(),
      Text('You\'ve recorded ${daysCounted.length} of the last 7 days', style: TextStyle(color: Colors.black54),)
    ]);
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
            padding: const EdgeInsets.all(10),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                [
                  Text(
                      '${DateFormat('EEEE').format(DateTime.now())}\'s Entry: ',
                      style: TextStyle(
//                          fontWeight: FontWeight.bold,
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

  Widget playRecordSection() {
    Function onpressed;
    if (_isRecording || _path == null) {
      onpressed = null;
    } else if (_isPlaying) {
      onpressed = stopPlayer;
    } else {
      onpressed = startPlayer;
    }

    return Expanded(child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RawMaterialButton(
              onPressed: (this._path != null && !_isRecording ? resetRecording : null),
                child: Icon(Icons.delete,
                    color: (this._path != null && !_isRecording ? Colors.black : Colors.grey[350]),
                    size: 70),
                shape: CircleBorder(),
                elevation: 2.0,
                fillColor: Colors.grey[200],
                padding: const EdgeInsets.all(4.0),
              ),
              RawMaterialButton(
                onPressed: (this._recordingLimitReached || this._isPlaying ? null : _toggleRecording),
                child: recordingButton(),
                shape: CircleBorder(),
                elevation: 2.0,
                fillColor: Colors.grey[200],
                padding: const EdgeInsets.all(4.0),
              ),
              Container(
                width: 82,
                height: 82,
              )
            ],
          ),
          Column(
            children: [
              statusText(),
              Text(recorderText),
            ]
          ),
          LinearProgressIndicator(
              value: _currentPosition / _maxRecordingLength,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              backgroundColor: Colors.red),
        ]
    ));
  }

  Widget statusText() {
    if (_fileSaved) {
     return Text('Saved');
    } else if (_isRecording) {
      return Text('Recording');
    } else if (this._path != null) {
      return Text('Save Recording?');
    } else {
      return Text('Ready');
    }
  }

  Widget recordingButton() {
    // Indicated disabled record button when playing audio
    Color micColor = (_isPlaying ? Colors.grey : Colors.red);

    if (audioState == t_AUDIO_STATE.IS_RECORDING) {
      return Icon(Icons.pause, color: Colors.black, size: 120);
    } else {
      return Icon(Icons.mic, color: micColor, size: 120);
    }
  }

  Future<void> resetRecording() async {
    _stopRecording();
    await stopPlayer();
    cancelPlayerSubscriptions();
    cancelRecorderSubscriptions();

    setState(() {
      this._recordingLimitReached = false;
      this._path = null;
      this._isPlaying = false;
      this._fileSaved = false;
      this._isRecording = false;
      this._currentPosition = 0;
      this.recorderText = _timeRemaining(0);
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
