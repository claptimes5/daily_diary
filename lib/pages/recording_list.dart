import 'package:flutter/material.dart';
import 'package:diary_app/models/recording.dart';
import 'package:diary_app/database_accessor.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';


class RecordingList extends StatefulWidget {
  @override
  RecordingListState createState() {
    return new RecordingListState();
  }
}

class RecordingListState extends State<RecordingList> {
  List<Recording> recordings;
  final DatabaseAccessor da = DatabaseAccessor();
  FlutterSound flutterSound = new FlutterSound();
  int recordPlaying;

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

          return ListView.builder(
            itemCount: recordings.length,
            itemBuilder: (context, i) {
              return listItem(recordings[i], i);
            }
          );
        }
      },
    );
  }

  Widget listItem(item, index) {
    return Dismissible(
      background: Container(color: Colors.red),
      key: Key(item.id.toString()),

      onDismissed: (direction) {
        int id = item.id;
        setState(() {
          da.delete(id);
          setState(() {
            recordings.removeAt(index);
          });
        });

        // Show a snackbar. This snackbar could also contain "Undo" actions.
        Scaffold
            .of(context)
            .showSnackBar(SnackBar(content: Text("$id dismissed")));
      },
      child: new Column(
        children: <Widget>[
          new Divider(
            height: 10.0,
          ),
          new ListTile(
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                da.delete(item.id);
                setState(() {});
              },
            ),
            title: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new Text(
                  item.time.toIso8601String(),
                  style:
                  new TextStyle(color: Colors.grey, fontSize: 14.0),
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
  Widget build(BuildContext context) {
    return recordingListView();
  }

  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  void playRecording(Recording recording){
    startPlayer(recording.path);
    setState(() {
      recordPlaying = recording.id;
    });
  }

  void startPlayer(path) async {
    try {
      stopPlayer();

      String path;
      if (await fileExists(path))
        path = await flutterSound.startPlayer(path);

      if (path == null) {
        print('Error starting player');
        return;
      }

      print('startPlayer: $path');
      await flutterSound.setVolume(1.0);

    } catch (err) {
      print('error: $err');
    }
    setState(() {});
  }

  void stopPlayer() async {
    try {
      await flutterSound.stopPlayer();
    } catch (err) {
      print('error: $err');
    }
  }

  Future<List<Recording>> getRecordings() async {


    return da.recordings();
  }
}
