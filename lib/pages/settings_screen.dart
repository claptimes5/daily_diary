import 'package:diary_app/ui/common_switch.dart';
import 'package:diary_app/ui/input_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  int recordingLength = 15;
  TextEditingController _recordingLengthEditingController = TextEditingController();
  TimeOfDay notificationTime = TimeOfDay(hour: 21, minute: 0);
  bool displayNotifications = false;
  final recordingLengthKey = 'recording_lehgth';
  SharedPreferences prefs;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void initState() {
    super.initState();
    _loadSettingsData();
    _initNotification();
  }

  _initNotification() async {
    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');

    var initializationSettingsIOS = IOSInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
        );

    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  _loadSettingsData() async {
    prefs = await SharedPreferences.getInstance();

    int _length = (prefs.getInt(recordingLengthKey) ?? 15);

    _recordingLengthEditingController.value = TextEditingValue(text: _length.toString());
    setState(() {
//      recordingLength = _length;
    });
  }

  void dispose() {
    _recordingLengthEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Settings"),
          elevation: 1.0,
        ),
        body: Container(child: bodyData())
    );
  }

  Widget bodyData() => SingleChildScrollView(

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "General Settings",
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Card(
            color: Colors.white,
            elevation: 2.0,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(
                    Icons.music_note,
                    color: Colors.green,
                  ),
                  title: Text("Recording Length (max 999)"),
                  trailing: Container(
                    width: 100,
                    child: TextField(
                      maxLength: 3,
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                        suffix: Text('seconds'),
                          counterText: '',
                          border: InputBorder.none
                      ),
                      controller: _recordingLengthEditingController,
                      onSubmitted: (String value) {
                        saveRecordingLength(value);
                      },
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        WhitelistingTextInputFormatter.digitsOnly
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: Colors.redAccent,
                  ),
                  title: Text("Daily Notifications"),
                  trailing: CommonSwitch(
                    defValue: displayNotifications,
                    onChanged: notificationToggled,
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.watch,
                    color: disabledSettingsColor(displayNotifications, Colors.grey),
                  ),
                  title: Text("Notification Time", style: TextStyle(color: disabledSettingsColor(displayNotifications, Colors.black))),
                  trailing: InkWell(
                    child: Text(notificationTime.format(context), style: TextStyle(color: disabledSettingsColor(displayNotifications, Colors.black))),
//                    valueStyle: valueStyle,
                    onTap: (displayNotifications ? () {
                      _selectTime(context);
                    } : null),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
  );

  notificationToggled(val) {
    if (val) {
      _enableNotifications();
    } else {
      _cancelNotifications();
    }

    setState(() {
      this.displayNotifications = val;
    });
  }

  Color disabledSettingsColor(bool isActive, Color defaultColor) {
    return (isActive ? defaultColor : Colors.black26);
  }
  
  void saveRecordingLength(String value) {
    int newValue;

    try {
     newValue = int.parse(value);
    } catch (FormatException) {
      newValue = 15;
    }
    // Prevent a user setting this to null or 0
    if (newValue == 0) {
      newValue = 15;
    }

    prefs.setInt(recordingLengthKey, newValue).then((bool success) {
      setState(() {
        recordingLength = newValue;
      });

      _loadSettingsData();
      return success;
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay picked =
    await showTimePicker(context: context, initialTime: notificationTime);
    if (picked != null && picked != notificationTime) {
//      TimeOfDay _startTime = TimeOfDay(hour:int.parse(s.split(":")[0]),minute: int.parse(s.split(":")[1]));

      setState(() {
        notificationTime = picked;
      });

      _cancelNotifications();
      _enableNotifications();
    }
  }

  _checkNotificationPermissions() async {
    if (Platform.isIOS) {
      var result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  _enableNotifications() async {
    _checkNotificationPermissions();

    var androidPlatformChannelSpecifics =
    AndroidNotificationDetails('repeatDailyAtTime channel id',
        'repeatDailyAtTime channel name', 'repeatDailyAtTime description');
    var iOSPlatformChannelSpecifics =
    IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    print(notificationTime);
    print(Time(notificationTime.hour, notificationTime.minute).toMap().toString());
    await flutterLocalNotificationsPlugin.showDailyAtTime(
        0,
        'Daily reminder',
        'Time to record your diary entry',
        Time(notificationTime.hour, notificationTime.minute),
        platformChannelSpecifics);
  }

  _cancelNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}