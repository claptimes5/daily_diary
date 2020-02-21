import 'package:flutter/material.dart';
import 'package:diary_app/models/recording.dart';
import 'package:diary_app/database_accessor.dart';
import 'package:diary_app/models/recording_provider.dart';

class RecordingList extends StatefulWidget {
  @override
  RecordingListState createState() {
    return new RecordingListState();
  }
}

class RecordingListState extends State<RecordingList> {
  List<Recording> recordings = [];

  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // your login goes here

    getRecordings().then((data) {
      recordings = data;
    });
    });
  }

  @override
  Widget build(BuildContext context) {



    return new ListView.builder(
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
                setState(() {
                  dummyData.removeAt(i);
                });
              },
            ),

//            leading: new CircleAvatar(
//              foregroundColor: Theme
//                  .of(context)
//                  .primaryColor,
//              backgroundColor: Colors.grey,
//              backgroundImage: new NetworkImage(dummyData[i].avatarUrl),
//            ),
            title: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
//                new Text(
//                  dummyData[i].name,
//                  style: new TextStyle(fontWeight: FontWeight.bold),
//                ),
                new Text(
                  recordings[i].time.toIso8601String(),
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



  Future<List<Recording>> getRecordings() async {
//    final RecordingProvider rp = RecordingProvider().open(path)
    
    final DatabaseAccessor da = DatabaseAccessor();

    return da.recordings();
  }
}
