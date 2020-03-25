import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:diary_app/models/recording.dart';
import 'package:diary_app/database_accessor.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_share/flutter_share.dart';

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
    initializeDateFormatting();
  }

  Widget recordingListView() {
    return FutureBuilder(
      future: getRecordings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(child: Text('No Recordings Yet'));
        } else if (snapshot.hasError) {
          return Container(child: Text('Error getting data'));
        } else {
          recordings = snapshot.data;

          if (recordings.isEmpty) {
            return Container(child: Center(child: Text('No Recordings Yet')));
          }

          return ListView.builder(
              itemCount: recordings.length,
              itemBuilder: (context, i) {
                return listItem(recordings[i], i);
              });
        }
      },
    );
  }

  void deleteRecording(Recording r) {
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

  Widget listItem(item, index) {
    final formatter = new DateFormat('MMMM dd, yyyy - h:mm a');
    Color backgroundColor;
    Color textColor;

    backgroundColor = (recordPlaying == item.id ? Colors.greenAccent : Colors.transparent);
    textColor = (recordPlaying == item.id ? Colors.white : Colors.black);

    return Dismissible(
      background: Container(color: Colors.red),
      key: Key(item.id.toString()),
      onDismissed: (direction) {
        int id = item.id;
        setState(() {
          deleteRecording(item);

          setState(() {
            recordings.removeAt(index);
          });
        });

        // Show a snackbar. This snackbar could also contain "Undo" actions.
        Scaffold.of(context)
            .showSnackBar(SnackBar(content: Text("$id dismissed")));
      },
      child: new Column(
        children: <Widget>[
          Divider(
            height: 10.0,
          ),
      Container(
        color: backgroundColor,
            child: ListTile(
              trailing: IconButton(
                  icon: (item.id == recordPlaying
                      ? Icon(Icons.stop)
                      : Icon(Icons.play_circle_filled)),
                  onPressed: () {
                    if (item.id == recordPlaying) {
                      stopPlayer();
                    } else {
                      playRecording(item);
                    }
                  },
                ),
            title: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  formatter.format(item.time),
                  style: new TextStyle(color: textColor, fontSize: 14.0),
                ),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {
                    shareFile(item.path);
                  },
                )
              ],
            ),
// TODO: Add location
//            subtitle: new Container(
//              padding: const EdgeInsets.only(top: 5.0),
//              child: new Text(
//                'Washington, D.C.',
//                style: new TextStyle(color: textColor, fontSize: 15.0),
//              ),
//            ),
          )
      )
        ],
      ),
    );
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
    return Column(
        children: [filterBar(), Expanded(child: recordingListView()), playerSection()]);
  }

  Widget playerSection() {
    Color playPauseColor;

    if (isPlayAllPaused() || isPlayerStopped()) {
      playPauseColor = Colors.green;
    } else {
      playPauseColor = Colors.red;
    }

    return Container(
      color: Colors.black12,
      child: Column(children: [
        Text(playingText(),
        style: TextStyle(
          fontSize: 18,
          color: Colors.black
        )),
        Row(
        mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
          IconButton(
            icon: Icon(Icons.stop, size: 50,),
            onPressed: resetPlayAll,
            iconSize: 50,
              color: Colors.black87
          ),
            IconButton(
              icon: Icon(
                  (isPlayAllPaused() || isPlayerStopped() ? Icons
                      .play_circle_outline : Icons
                      .pause_circle_filled), size: 40,
                  color: playPauseColor),
              onPressed: togglePlayAll,
            iconSize: 40,
          ),
        ],)

      ]),
      padding: EdgeInsets.all(10.0),);
  }

  String playingText() {
    if (isPlayAllPlaying() || isPlayAllPaused()) {
      return "Playing ${recordIndexPlaying + 1} of ${recordings.length}";
    } else {
      return 'Play all: stopped';
    }
  }

  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  void playRecording(Recording recording) {
    startPlayer(recording);
  }

  void startPlayer(recording, {Function onPlayerStateChangedCallback}) async {
    String path = recording.path;
    print('startPlayer called');
    print('playing status: ${flutterSound.audioState}');
    try {
      print('stopping player');
      await stopPlayer();

      print('playing file');
      print(path);
      if (await fileExists(path)) {
        path = await flutterSound.startPlayer(path);
      }

      print('startPlayer: $path');

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
