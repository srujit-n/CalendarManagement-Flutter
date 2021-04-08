import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState()  => CalendarState();
}
class CalendarState extends State<CalendarPage>{
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    DateTime _focusedDay = DateTime.now();
    DateTime _selectedDay;
    double width  = MediaQuery.of(context).size.width;
      return SafeArea(
        child: Scaffold(
          body: Container(
            width: width,
            height: height,
            child: TableCalendar(
              firstDay: DateTime.utc(DateTime.now().year,01,01),
              lastDay: DateTime.utc(DateTime.now().year+1,01,01),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = selectedDay; // update `_focusedDay` here as well
                });
              },
            ),
          ),
        ),
      );
  }

}