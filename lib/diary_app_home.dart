import 'package:flutter/material.dart';
import 'package:diary_app/pages/recording_list.dart';
import 'package:diary_app/pages/recording_screen.dart';

class DiaryAppHome extends StatefulWidget {
  @override
  _DiaryAppHomeState createState() => _DiaryAppHomeState();
}

class _DiaryAppHomeState extends State<DiaryAppHome>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(vsync: this, initialIndex: 1, length: 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Daily Diary"),
        elevation: 0.7,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: <Widget>[
            Tab(text: "Record New"),
            Tab(
              text: "List Recordings",
            ),
          ],
        ),
        actions: <Widget>[
          Icon(Icons.search),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
          ),
          Icon(Icons.more_vert)
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          RecordingScreen(),
          RecordingList(),
        ],
      ),
    );
  }
}
