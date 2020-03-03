import 'dart:async';

import 'package:flutter/material.dart';
import 'package:diary_app/models/recording.dart';
import 'package:diary_app/database_accessor.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class RecordingList extends StatefulWidget {
  @override
  RecordingListState createState() {
    return new RecordingListState();
  }
}

class RecordingListState extends State<RecordingList> {
  List<Recording> recordings;
  final DatabaseAccessor da = DatabaseAccessor();
  FlutterSound flutterSound;
  int recordPlaying;
  bool _filterOpen = false;
  StreamSubscription _playerSubscription;
  List<Map> dateRangeOptions = [
    {'name': '1 week', 'value': '1_week'},
    {'name': '1 month', 'value': '1_month'},
    {'name': '1 year', 'value': '1_year'},
    {'name': 'All', 'value': 'all'}
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
          //print('project snapshot data is: ${projectSnap.data}');
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
    File(r.path).deleteSync();

    da.delete(r.id);
  }

  Widget filterBar() {
    List<Widget> filterBarContents = [
      Container(
          padding: EdgeInsets.only(left: 10.0, right: 5.0),
          child: Row(children: [
            Expanded(child: Text('Filter Options')),
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
          new Divider(
            height: 10.0,
          ),
          new ListTile(
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
                new Text(
                  formatter.format(item.time),
                  style: new TextStyle(color: Colors.grey, fontSize: 14.0),
                ),
              ],
            ),
            subtitle: new Container(
              padding: const EdgeInsets.only(top: 5.0),
              child: new Text(
                'Washington, D.C.',
                style: new TextStyle(color: Colors.grey, fontSize: 15.0),
              ),
            ),
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
        children: [filterBar(), Expanded(child: recordingListView())]);
  }

  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  void playRecording(Recording recording) {
    startPlayer(recording);
  }

  void startPlayer(recording) async {
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
      await flutterSound.setVolume(1.0);

      _playerSubscription = flutterSound.onPlayerStateChanged.listen((e) {
        if (e != null) {
          if (flutterSound.audioState == t_AUDIO_STATE.IS_STOPPED) {
            setState(() {
              recordPlaying = null;
            });
          }
        }
      });

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
      if (flutterSound.audioState == t_AUDIO_STATE.IS_PLAYING) {
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
          print(_filterOption);
          startTime = now.subtract(Duration(days: 7));
        }
        break;
      case '1_month':
        {
          print(_filterOption);
          startTime = now.subtract(Duration(days: 31));
        }
        break;

      case '1_year':
        {
          print(_filterOption);
          startTime = now.subtract(Duration(days: 365));
        }
        break;

      default:
        startTime = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return da.recordings(startTime: startTime, endTime: endTime);
  }
}
