import 'package:flutter/material.dart';
import 'package:diary_app/models/recording.dart';
import 'package:diary_app/database_accessor.dart';

class RecordingList extends StatefulWidget {
  @override
  RecordingListState createState() {
    return new RecordingListState();
  }
}

class RecordingListState extends State<RecordingList> {
  List<Recording> recordings;
  final DatabaseAccessor da = DatabaseAccessor();

//  @override
//  void initState() {
//    super.initState();
//  }

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
            itemBuilder: (context, i) => new Column(
              children: <Widget>[
                new Divider(
                  height: 10.0,
                ),
                new ListTile(
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      da.delete(recordings[i].id);
                      setState(() {
                        recordings.removeAt(i);
                      });
                    },
                  ),
                  title: new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new Text(
                        recordings[i].time.toIso8601String(),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return recordingListView();
  }

  Future<List<Recording>> getRecordings() async {


    return da.recordings();
  }
}
