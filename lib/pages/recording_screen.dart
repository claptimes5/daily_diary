import 'package:flutter/material.dart';

class RecordingScreen extends StatefulWidget {
  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool _isRecording = false;
  final int _maxRecordingLength = 15;

  @override
  Widget build(BuildContext context) {
    return _buildPage();
  }

  void _toggleRecording() {
    setState(() {
      if (_isRecording) {
        _stopRecording();
      } else {
        _startRecording();
      }
    });
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
  }

  Widget _buildPage() {
    return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [titleSection, recordSection(), playSection, saveSection],
        ));
  }

  Widget titleSection = Container(
      padding: const EdgeInsets.all(32),
      child: Text(
        'Record for today __',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ));

  Widget recordSection() {
    return Container(
      padding: const EdgeInsets.all(32),
        child: Column(children: [
          IconButton(icon: (_isRecording ? Icon(Icons.stop, color: Colors.grey, size: 100) : Icon(Icons.fiber_manual_record, color: Colors.red, size: 100)),
              onPressed: _toggleRecording,
          iconSize: 100,),
          Text('15 Seconds')
        ]));
  }

  Widget playSection = Container(
      padding: const EdgeInsets.all(32),
      child: Center(
          child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Icon(Icons.fast_rewind, size: 70),
            Icon(Icons.play_arrow, size: 70)
          ])));

  Widget saveSection = Container(
//      padding: const EdgeInsets.all(32),
      child: IconButton(
        icon: Icon(Icons.save),
        onPressed: () {},
      ));
}
