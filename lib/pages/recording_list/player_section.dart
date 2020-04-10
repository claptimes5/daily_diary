import 'package:flutter/material.dart';

class PlayerSection extends StatelessWidget {
  final Function onStopPressed;
  final Function onPlayPauseToggle;
  final bool isStopped;
  final int recordIndexPlaying;
  final int recordingsLength;

  PlayerSection(
      {@required this.onStopPressed,
      @required this.onPlayPauseToggle,
      this.isStopped = false,
      this.recordIndexPlaying,
      this.recordingsLength});

  @override
  Widget build(BuildContext context) {
    Color playPauseColor;

    if (isStopped) {
      playPauseColor = Colors.green;
    } else {
      playPauseColor = Colors.red;
    }

    return Container(
      color: Colors.black12,
      child: Column(children: [
        Text(playingText(),
            style: TextStyle(fontSize: 18, color: Colors.black)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
                icon: Icon(
                  Icons.stop,
                  size: 50,
                ),
                onPressed: onStopPressed,
                iconSize: 50,
                color: Colors.black87),
            IconButton(
              icon: Icon(
                  (isStopped
                      ? Icons.play_circle_outline
                      : Icons.pause_circle_filled),
                  size: 40,
                  color: playPauseColor),
              onPressed: onPlayPauseToggle,
              iconSize: 40,
            ),
          ],
        )
      ]),
      padding: EdgeInsets.all(10.0),
    );
  }

  String playingText() {
    if (isStopped || recordIndexPlaying == null) {
      return 'Play all: stopped';
    } else {
      return "Playing ${recordIndexPlaying + 1} of $recordingsLength";
    }
  }
}
