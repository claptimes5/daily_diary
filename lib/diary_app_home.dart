import 'package:diary_app/pages/settings_screen.dart';
import 'package:diary_app/ui/circle_tab_indicator.dart';
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

    tabController = TabController(vsync: this, initialIndex: 0, length: 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Daily Diary"),
        elevation: 1.0,
        bottom: TabBar(
          indicator: CircleTabIndicator(color: Colors.blue[100], radius: 3),
          controller: tabController,
          indicatorColor: Colors.white,
          tabs: <Widget>[
            Tab(child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.add), Text("Add Entry")],)),
            Tab(child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_filled),
                Text("Listen"),
              ],)),
            Tab(child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.settings),
                Text("Settings"),
              ],)),
          ],
        ),
        actions: <Widget>[
//          Icon(Icons.search),
//          Padding(
//            padding: const EdgeInsets.symmetric(horizontal: 5.0),
//          ),
//          IconButton(icon: Icon(Icons.settings),
//            onPressed: () {
//              Navigator.push(
//                context,
//                MaterialPageRoute(builder: (context) => SettingsScreen()),
//              ).then((value) {
//                setState(() {
////                  _max
//                });
//              });
//            },
//          )
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: <Widget>[
          RecordingScreen(),
          RecordingList(),
          SettingsScreen(),
        ],
      ),
    );
  }


}
