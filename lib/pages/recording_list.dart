import 'package:flutter/material.dart';
import 'package:diary_app/models/recording.dart';

class RecordingList extends StatefulWidget {
  @override
  RecordingListState createState() {
    return new RecordingListState();
  }
}

class RecordingListState extends State<RecordingList> {
  @override
  Widget build(BuildContext context) {
    return new ListView.builder(
      itemCount: dummyData.length,
      itemBuilder: (context, i) =>
      new Column(
        children: <Widget>[
          new Divider(
            height: 10.0,
          ),
          new ListTile(
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
                  dummyData[i].time.toIso8601String(),
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
}