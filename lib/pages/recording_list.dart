import 'dart:async';
import 'package:diary_app/pages/recording_list/list_section.dart';
import 'package:diary_app/pages/recording_list/player_section.dart';
import 'package:flutter/material.dart';
import 'package:diary_app/models/recording.dart';
import 'package:diary_app/database_accessor.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';
import 'package:flutter_share/flutter_share.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class RecordingList extends StatefulWidget {
  @override
  RecordingListState createState() {
    return new RecordingListState();
  }
}

class RecordingListState extends State<RecordingList> {
  List<Recording> recordings = [];
  final DatabaseAccessor da = DatabaseAccessor();
  FlutterSound flutterSound;
  int recordPlaying; // The ID of the record that is playing
  int recordIndexPlaying; // The index of the record that is playing in the `recordings` list
  bool _filterOpen = false;
  StreamSubscription _playerSubscription;
  List<Map> dateRangeOptions = [
    {'name': 'Past week', 'value': '1_week'},
    {'name': 'Past month', 'value': '1_month'},
    {'name': 'Past year', 'value': '1_year'},
    {'name': 'All time', 'value': 'all'}
  ];
  String _filterOption = 'all';

  void initState() {
    super.initState();
    flutterSound = new FlutterSound();
    flutterSound.setSubscriptionDuration(0.01);
    flutterSound.setDbPeakLevelUpdate(0.8);
    flutterSound.setDbLevelEnabled(true);
//    initializeDateFormatting();
  }

  void deleteRecording(DismissDirection direction, Recording r, int index) {
    setState(() {
      deleteRecordingFromFileAndDb(r);

      setState(() {
        recordings.removeAt(index);
      });
    });

    Scaffold.of(context)
        .showSnackBar(
        SnackBar(content: Text("Recording was deleted")));
  }

  void deleteRecordingFromFileAndDb(Recording r) {
    try {
      File(r.path).deleteSync();
    } on FileSystemException catch (e) {
      print('File did not exist. Will delete from database.');
      print(e.toString());
    }

    da.delete(r.id);
  }

  void onPlayerStateChanged() {
    _playerSubscription = flutterSound.onPlayerStateChanged.listen((e) {
      if (e != null) {
        if (flutterSound.audioState == t_AUDIO_STATE.IS_STOPPED) {
          setState(() {
            if (recordIndexPlaying < recordings.length - 1) {
              recordIndexPlaying++;
            } else {
              recordIndexPlaying = null;
            }

          });

          if (recordIndexPlaying != null) {
            startPlayer(recordings[recordIndexPlaying],
                onPlayerStateChangedCallback: onPlayerStateChanged);
          } else {
            stopPlayer();
          }
        }
      }
    });
  }

  void resetPlayAll() {
      stopPlayer();
      setState(() {
        recordIndexPlaying = null;
      });

  }

  void togglePlayAll() async {
    if (isPlayAllPlaying()) {
      await flutterSound.pausePlayer();
      setState(() {});
    } else if (isPlayAllPaused()) {
      await flutterSound.resumePlayer();
      setState(() {});
    } else {
      setState(() {
        recordIndexPlaying = 0;
      });
      startPlayer(recordings[recordIndexPlaying], onPlayerStateChangedCallback: onPlayerStateChanged);
    }
  }

  bool isPlayAllPaused() {
    return recordIndexPlaying != null && flutterSound.audioState == t_AUDIO_STATE.IS_PAUSED;
  }

  bool isPlayerStopped() {
    return flutterSound.audioState == t_AUDIO_STATE.IS_STOPPED;
  }

  bool isPlayAllPlaying() {
    return recordIndexPlaying != null && flutterSound.audioState == t_AUDIO_STATE.IS_PLAYING;
  }

  Widget filterBar() {
    Map option = dateRangeOptions.firstWhere((option) => option['value'] == _filterOption);
    String filterText = 'Display: ${option['name']}';

    List<Widget> filterBarContents = [
      Container(
          padding: EdgeInsets.only(left: 10.0, right: 5.0),
          child: Row(children: [
            Expanded(child: Text(filterText)),
            Text('${recordings.length} recordings'),
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: () {
                setState(() {
                  _filterOpen = !_filterOpen;
                });
              },
            ),
          ]))
    ];

    if (_filterOpen) {
      filterBarContents += dateRangeOptions.map((element) {
        return RadioListTile(
          title: Text(element['name']),
            value: element['value'],
            groupValue: _filterOption,
            onChanged: (value) {
              setState(() {
                _filterOption = value;
              });
            },
        );
      }).toList();
    }

    return Column(children: filterBarContents);
  }

  @override
  void dispose() {
    flutterSound.stopPlayer().catchError((e, trace) {
      print('Stop player failed because it was not running');
    }, test: (e) => e is PlayerRunningException);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getRecordings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError) {
          recordings = [];
        } else {
          recordings = snapshot.data;
        }

        return Column(
            children: [
              filterBar(),
              Expanded(child: ListSection(
                recordings: snapshot.data,
                recordPlaying: recordPlaying,
                onRecordingDismissed: deleteRecording,
                onItemPlay: playRecording,
                onItemStop: stopPlayer,
                onItemShare: shareFile,
              )),
              PlayerSection(
                  onStopPressed: resetPlayAll,
                  onPlayPauseToggle: togglePlayAll,
                  isStopped: (isPlayAllPaused() || isPlayerStopped()),
                  recordIndexPlaying: recordIndexPlaying,
                  recordingsLength: recordings.length)
            ]
        );
      },
    );
  }

  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  void playRecording(Recording recording) {
    startPlayer(recording);
  }

  void startPlayer(recording, {Function onPlayerStateChangedCallback}) async {
    String path = recording.path;
    Directory appDocDir;
    print('startPlayer called');
    print('playing status: ${flutterSound.audioState}');
    try {
      print('stopping player');
      await stopPlayer();

      // Versions of the app > 0.1.1 use relative path to store files. This determines if
      // a relative path was used and prepends the appropriate path prefix.
      if (path.startsWith('/')) {
        // Split the absolute path and the prepend the file name with the diary entries directory
        // to construct the appropriate relative path
        path = path.split('/').last;
        path = p.join('diary_entries', path);
      }

      if (Platform.isAndroid) {
        appDocDir = await getExternalStorageDirectory();
      } else {
        appDocDir = await getApplicationDocumentsDirectory();
      }

      path = p.join(appDocDir.path, path);;

      print('playing file $path');
      if (await fileExists(path)) {
        path = await flutterSound.startPlayer(path);
      }

      if (onPlayerStateChangedCallback != null) {
        onPlayerStateChangedCallback();
      } else {
        _playerSubscription = flutterSound.onPlayerStateChanged.listen((e) {
          if (e != null) {
            if (flutterSound.audioState == t_AUDIO_STATE.IS_STOPPED) {
              setState(() {
                recordPlaying = null;
              });
            }
          }
        });
      }

      setState(() {
        recordPlaying = recording.id;
      });
    } catch (err) {
      print('error: $err');
      stopPlayer();
    }
    setState(() {});
  }

  Future stopPlayer() async {
    print('stopPlayer called');
    print('playing status: ${flutterSound.audioState}');
    try {
      if (flutterSound.audioState == t_AUDIO_STATE.IS_PLAYING || flutterSound.audioState == t_AUDIO_STATE.IS_PAUSED) {
        String result = await flutterSound.stopPlayer();
        print('stopPlayer: $result');
      }

      if (_playerSubscription != null) {
        _playerSubscription.cancel();
        _playerSubscription = null;
      }
    } catch (err) {
      print('error: $err');
    }

    setState(() {
      recordPlaying = null;
    });
  }

  Future<List<Recording>> getRecordings() async {
    DateTime now = DateTime.now();
    DateTime startTime = DateTime.fromMillisecondsSinceEpoch(0);
    DateTime endTime = now;

    switch (_filterOption) {
      case '1_week':
        {
          startTime = now.subtract(Duration(days: 7));
        }
        break;
      case '1_month':
        {
          startTime = now.subtract(Duration(days: 31));
        }
        break;

      case '1_year':
        {
          startTime = now.subtract(Duration(days: 365));
        }
        break;

      default:
        startTime = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return da.recordings(startTime: startTime, endTime: endTime);
  }

  Future<void> shareFile(path) async {
    await FlutterShare.shareFile(
      title: 'Share recording',
      filePath: path,
    );
  }
}
