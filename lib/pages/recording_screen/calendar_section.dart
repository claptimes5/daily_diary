import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarSection extends StatelessWidget {
  final Map<DateTime, List> events;
  final bool isTodaysEntryComplete;
  final CalendarController calendarController;

  CalendarSection(
      {this.events, this.isTodaysEntryComplete, this.calendarController});

  @override
  Widget build(BuildContext context) {
    Map daysCounted = {};

    // Count the number of unique events per day
    events.keys.forEach((e) {
      daysCounted[e.day] = 1;
    });

    return Column(children: [
      _buildTableCalendar(),
      Text(
        'You\'ve recorded ${daysCounted.length} of the last 7 days',
        style: TextStyle(color: Colors.black54),
      )
    ]);
  }

  Widget _buildTableCalendar() {
    Color todayColor = Colors.red[300];

    // snapshot.data returns true if entry is complete for today
    if (isTodaysEntryComplete) {
      todayColor = Colors.green;
    }

    final startingDay = DateTime.now().subtract(Duration(days: 6));
    final endDay = DateTime.now();

    return TableCalendar(
      calendarController: calendarController,
      events: events,
//      holidays: _holidays,
      initialCalendarFormat: CalendarFormat.week,
      startingDayOfWeek: StartingDayOfWeek.values[startingDay.weekday - 1],
      startDay: startingDay,
      endDay: endDay,
      calendarStyle: CalendarStyle(
        selectedColor: Colors.deepOrange[400],
        todayColor: todayColor,
        markersColor: Colors.green[700],
        outsideDaysVisible: false,
        highlightSelected: false,
        weekendStyle: null,
        outsideWeekendStyle: null,
      ),
      headerVisible: false,
      availableGestures: AvailableGestures.none,
      daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: const Color(0xFF616161)),
          weekendStyle: TextStyle(color: const Color(0xFF616161))),
      headerStyle: HeaderStyle(
        centerHeaderTitle: true,
        formatButtonVisible: false,
        headerPadding: EdgeInsets.symmetric(vertical: 2.0),
      ),
    );
  }
}
