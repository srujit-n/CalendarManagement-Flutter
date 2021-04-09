import 'dart:collection';
import 'dart:math';

import 'package:calendar_management/LogIn.dart';
import 'package:calendar_management/emailtext.dart';
import 'package:calendar_management/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:table_calendar/table_calendar.dart';

import 'auth.dart';
import 'datepicker.dart';
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
  List<String> emails=[];
  LinkedHashMap kEvents= LinkedHashMap();
   ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  List<Map> events=[];
  TextEditingController event = TextEditingController();
  TextEditingController desc = TextEditingController();
  DateTime _selectedDay;
  DateTime EventDate = DateTime.now();
  Map res = Map();
  @override
  void initState() {
    super.initState();
    getEventData().then((value){
      setState(() {
        res=value;
      });
      print(res);
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
  Future setEvents() async {
    events.add({
      "Event": event.text,
      "description": desc.text,
      "users": emails
    });
    final snapShot =
    await databaseReference.collection('Users').doc(Auth()
        .getCurrentUser()
        .uid).get();
    print(snapShot.exists);
    if (snapShot.exists) {
      DocumentReference newData =
      databaseReference.collection("Users").doc(Auth()
          .getCurrentUser()
          .uid);
      newData.update({
        DateFormat('yyyy-MM-dd').format(_focusedDay): events
      });
      print('Event Added');
    }
  }

   static const _actionTitles = ['Create an event', 'Send reminders'];
   void _showAction(BuildContext context, int index) {
     showDialog<void>(
       context: context,
       builder: (context) {
         return AlertDialog(
           content:Container(
             height: MediaQuery.of(context).size.height/3,
             child: Column(
               children: [
                 IgnorePointer(
                   child: MyTextFieldDatePicker(
                     prefixIcon: Icon(Icons.calendar_today_rounded),
                     firstDate: kFirstDay,
                     lastDate: kLastDay,
                     initialDate: _focusedDay, onDateChanged: (DateTime value) {
                       if(mounted)
                       setState(() {
                         EventDate =value;
                       });
                       print(EventDate);
                   },
                   ),
                 ),
                 SizedBox( height: 8),
                 TextField(
                   controller: event,
                   decoration: InputDecoration(
                     border: OutlineInputBorder(),
                     labelText: "Event",
                     hintText: "Enter Event Name"
                   ),
                 ),
                 SizedBox( height: 8),
                 TextField(
                   controller: desc,
                   decoration: InputDecoration(
                       border: OutlineInputBorder(),
                       labelText: "Description",
                       hintText: "Enter Event Description"
                   ),
                 ),
                 SizedBox( height: 8),
                 EmailInput(parentEmails: emails,)
               ],
             ),
           ),
           title:  Text(_actionTitles[index]),
           actions: [
             TextButton(
               onPressed: () => Navigator.of(context).pop(),
               child: const Text('CANCEL',style:TextStyle(color: Colors.red),),
             ),
             TextButton(
               onPressed: (){
                 print(emails);
                 setEvents().whenComplete(() => Navigator.of(context).pop());
               },
               child: const Text('OK'),),
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