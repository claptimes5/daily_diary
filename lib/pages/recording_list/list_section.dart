import 'package:diary_app/models/recording.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ListSection extends StatelessWidget {
  final List<Recording> recordings;
  final int recordPlaying;
  final Function onRecordingDismissed;
  final Function onItemStop;
  final Function onItemPlay;
  final Function onItemShare;

  ListSection(
      {@required this.recordings,
      @required this.recordPlaying,
      @required this.onRecordingDismissed,
      @required this.onItemStop,
      @required this.onItemPlay,
      @required this.onItemShare});

  @override
  Widget build(BuildContext context) {
    if (recordings == null || recordings.isEmpty) {
      return Container(child: Center(child: Text('No Recordings Yet')));
    }

    return ListView.builder(
        itemCount: recordings.length,
        itemBuilder: (context, i) {
          return listItem(context, recordings[i], i);
        });
  }

  Widget listItem(BuildContext context, item, index) {
    final formatter = new DateFormat('MMMM dd, yyyy - h:mm a');
    Color backgroundColor;
    Color textColor;

    backgroundColor =
        (recordPlaying == item.id ? Colors.greenAccent : Colors.transparent);
    textColor = (recordPlaying == item.id ? Colors.white : Colors.black);

    return Dismissible(
      background: Container(color: Colors.red),
      key: Key(item.id.toString()),
      confirmDismiss: (direction) async {
        return confirmDeletion(context);
      },
      onDismissed: (direction) {
        onRecordingDismissed(direction, item, index);
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
                      onItemStop();
                    } else {
                      onItemPlay(item);
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
                        onItemShare(item.path);
                      },
                    )
                  ],
                ),
              ))
        ],
      ),
    );
  }

  Future<bool> confirmDeletion(BuildContext context) async {
    return showDialog<bool>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Are you sure?"),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Please confirm deletion.'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              FlatButton(
                child: Text('Confirm'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        });
  }
}
