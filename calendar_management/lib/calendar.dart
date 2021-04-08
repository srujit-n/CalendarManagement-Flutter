import 'dart:collection';

import 'package:calendar_management/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'fab.dart';

class CalendarPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState()  => CalendarState();
}
class CalendarState extends State<CalendarPage> {

  Future<Map> getEventData() async{
    Map temp={};
    await databaseRef.then((s){
      setState(() {
        temp = s.data().containsKey("Events")?s.get("Events"):{DateTime.now():List.generate(2, (index) =>  Event('Event${index + 1}',users))};
      });
    });
    return temp;
  }
  final _kEventSource = Map.fromIterable(List.generate(50, (index) => index),
      key: (item) => DateTime.utc(2020, 10, item * 5),
      value: (item) => List.generate(
          item % 4 + 1, (index) => Event('Event $item | ${index + 1}',users)))
    ..addAll({
      DateTime.now(): [
        Event('Today\'s Event 1',[]),
        Event('Today\'s Event 2',[]),
      ],
    });
  LinkedHashMap kEvents= LinkedHashMap();
   ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay;
  Map res = Map();
  @override
  void initState() {
    super.initState();
    DateFormat s = DateFormat.yMMMd();
    getEventData().then((value){
      setState(() {
        res=value;
      });
      print(res);
      Map<DateTime,dynamic>_kEventSource1 = Map.fromIterable(res.entries,
          key: (item) => item.toDate(),
          value: (value) => value);
      kEvents = LinkedHashMap<DateTime, List<Event>>(
        equals: isSameDay,
        hashCode: getHashCode,
      )..addAll(_kEventSource);
    });
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {
    // Implementation example
    return kEvents[day] ?? [];
  }
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

   static const _actionTitles = ['Create an event', 'Send reminders'];
   void _showAction(BuildContext context, int index) {
     showDialog<void>(
       context: context,
       builder: (context) {
         return AlertDialog(
           content: Text(_actionTitles[index]),
           actions: [
             TextButton(
               onPressed: () => Navigator.of(context).pop(),
               child: const Text('CLOSE'),
             ),
           ],
         );
       },
     );
   }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Calendar'),
      ),
      floatingActionButton: ExpandableFab(
        distance: 100.0,
        children: [
          ActionButton(
            onPressed: () => _showAction(context, 1),
            icon: const Icon(Icons.mail_outline_rounded),
          ),
          ActionButton(
            onPressed: () => _showAction(context, 0),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: kFirstDay,
            lastDay: kLastDay,
            daysOfWeekVisible: true,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            calendarBuilders: CalendarBuilders(
              singleMarkerBuilder: (context,DateTime t ,Event f){
                return Container(
                  decoration: new BoxDecoration(
                    color: const Color(0xff082649),
                    shape: BoxShape.circle,
                  ),
                  margin: EdgeInsets.symmetric(horizontal: width/150),
                  width: width / 80,
                  height: width / 80,
                );
              },
              todayBuilder:  (context,DateTime t ,DateTime f){
                return Container(
                  decoration: new BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black)
                  ),
                  margin: EdgeInsets.all(width / 100),
                  width: width / 11,
                  height: width / 11,
                  child: Center(
                    child: Text(
                      '${t.day}',
                    ),
                  ),
                );
              },
              selectedBuilder: (context,DateTime t ,DateTime f){
                return Container(
                  decoration: new BoxDecoration(
                    color: Color.fromRGBO(255, 197, 1, 1),
                    shape: BoxShape.circle,
                  ),
                  margin: EdgeInsets.all(width / 100),
                  width: width / 11,
                  height: width / 11,
                  child: Center(
                    child: Text(
                      '${t.day}',
                    ),
                  ),
                );
              }
            ),
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(

              // Use `CalendarStyle` to customize the UI
              outsideDaysVisible: true,
            ),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        onTap: () => print('${value[index]}'),
                        title: Text('${value[index]}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}