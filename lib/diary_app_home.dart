import 'package:flutter/material.dart';
import 'package:diary_app/pages/recording_list.dart';
import 'package:diary_app/pages/recording_screen.dart';

class DiaryAppHome extends StatefulWidget {
  @override
  DiaryAppHomeState createState() => DiaryAppHomeState();
}

class DiaryAppHomeState extends State<DiaryAppHome>
    with SingleTickerProviderStateMixin {
  TabController tabController;

  @override
  void initState() {
    super.initState();

    tabController = TabController(vsync: this, initialIndex: 0, length: 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Daily Diary"),
        elevation: 0.7,
        bottom: TabBar(
          controller: tabController,
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
        controller: tabController,
        children: <Widget>[
          RecordingScreen(),
          RecordingList(),
        ],
      ),
    );
  }
}
