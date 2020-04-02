import 'package:diary_app/ui/common_switch.dart';
import 'package:diary_app/ui/input_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  int recordingLength;
  TimeOfDay notificationTime = TimeOfDay.now();
  bool displayNotifications = false;
  final _formKey = GlobalKey<FormState>();

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
                  title: Text("Recording Length"),
                  trailing: CommonSwitch(
                    defValue: true,
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
                    onChanged: (val) {
                      setState(() {
                        this.displayNotifications = !displayNotifications;
                      });
                    },
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

  Color disabledSettingsColor(bool isActive, Color defaultColor) {
    return (isActive ? defaultColor : Colors.black26);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay picked =
    await showTimePicker(context: context, initialTime: notificationTime);
    if (picked != null && picked != notificationTime) {
     setState(() {
       notificationTime = picked;
     });
    }
  }

  Widget _formSection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Enter your email',
            ),
            validator: (value) {
              if (value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: RaisedButton(
              onPressed: () {
                // Validate will return true if the form is valid, or false if
                // the form is invalid.
                if (_formKey.currentState.validate()) {
                  // Process data.
                }
              },
              child: Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}