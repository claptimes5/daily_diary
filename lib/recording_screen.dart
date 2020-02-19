import 'package:flutter/material.dart';

class RecordingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Record an Entry')),
      body: _buildPage(),
      drawer: drawer,
    );
  }

  Widget drawer = Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: const <Widget>[
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: Text(
            'Daily Diary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.message),
          title: Text('Record New'),
        ),
        ListTile(
          leading: Icon(Icons.account_circle),
          title: Text('List Recordings'),
        ),
      ],
    ),
  );

  _buildPage() {
    return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [titleSection, recordSection, playSection, saveSection],
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

  Widget recordSection = Container(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        Icon(Icons.fiber_manual_record, color: Colors.red, size: 100),
        Text('15 Seconds')
      ]));

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
      padding: const EdgeInsets.all(32),
      child: IconButton(
        icon: Icon(Icons.save),
        onPressed: () {},
      ));
}
