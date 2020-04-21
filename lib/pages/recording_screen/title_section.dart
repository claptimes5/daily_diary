import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TitleSection extends StatelessWidget {
  final bool isTodaysEntryComplete;

  TitleSection({this.isTodaysEntryComplete});

  @override
  Widget build(BuildContext context) {
    String recordCompleteText = 'Incomplete';
    Color recordCompleteColor = Colors.redAccent;

    if (isTodaysEntryComplete) {
      recordCompleteText = 'Complete';
      recordCompleteColor = Colors.lightGreen;
    }

    return Container(
        padding: const EdgeInsets.all(10),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${DateFormat('EEEE').format(DateTime.now())}\'s Entry: ',
              style: TextStyle(fontSize: 22)),
          Text(recordCompleteText,
              style: TextStyle(color: recordCompleteColor, fontSize: 20))
        ]));
  }
}
