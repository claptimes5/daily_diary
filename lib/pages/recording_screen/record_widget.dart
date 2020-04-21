import 'package:flutter/material.dart';

class RecordWidget extends StatelessWidget {
  final String recordingPath;
  final bool isRecording;
  final Function onResetRecording;
  final Function onToggleRecording;
  final String recorderText;
  final int currentPosition;
  final int maxRecordingLength;
  final bool fileSaved;
  final bool recordingLimitReached;

  RecordWidget({
    this.recordingPath,
    this.isRecording,
    this.onResetRecording,
    this.recorderText,
    this.currentPosition,
    this.maxRecordingLength,
    this.fileSaved,
    this.onToggleRecording,
    this.recordingLimitReached
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RawMaterialButton(
                onPressed: (recordingPath != null && !isRecording
                    ? onResetRecording
                    : null),
                child: Icon(Icons.delete,
                    color: (recordingPath != null && !isRecording
                        ? Colors.black
                        : Colors.grey[350]),
                    size: 70),
                shape: CircleBorder(),
                elevation: 2.0,
                fillColor: Colors.grey[200],
                padding: const EdgeInsets.all(4.0),
              ),
              RawMaterialButton(
                onPressed: (this.recordingLimitReached
                    ? null
                    : onToggleRecording),
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
              value: currentPosition / maxRecordingLength,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              backgroundColor: Colors.red),
        ]
    ));
  }


  Widget recordingButton() {
    if (isRecording) {
      return Icon(Icons.pause, color: Colors.black, size: 120);
    } else {
      return Icon(Icons.mic, color: Colors.red, size: 120);
    }
  }

  Widget statusText() {
    if (fileSaved) {
      return Text('Saved');
    } else if (isRecording) {
      return Text('Recording');
    } else if (recordingPath != null) {
      return Text('Save Recording?');
    } else {
      return Text('Ready');
    }
  }
}