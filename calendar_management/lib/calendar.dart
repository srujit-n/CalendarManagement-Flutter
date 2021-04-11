import 'dart:collection';
import 'package:calendar_management/LogIn.dart';
import 'package:calendar_management/emailtext.dart';
import 'package:calendar_management/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'auth.dart';
import 'datepicker.dart';
import 'fab.dart';

class CalendarPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState()  => CalendarState();
}
class CalendarState extends State<CalendarPage> {
  List<String> emails=[Auth().getCurrentUser().email];
  LinkedHashMap kEvents= LinkedHashMap();
  ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  List  events=[];
  List<Map<DateTime,List<Event>>> events2=[];
  TextEditingController event = TextEditingController();
  TextEditingController timer = TextEditingController();
  TextEditingController desc = TextEditingController();
  DateTime _selectedDay;
  Timestamp t;
  DateTime eventDate = DateTime.now();
  Map res = Map();
  Future<void> getEventData() async{
    var d = await databaseReference.collection("Users").doc(Auth().getCurrentUser().uid).collection("Events").get();
    List<DateTime>dates=[];
    for(int i=0;i<d.docs.length;i++){
      List temp = (d.docs[i].get("EventList"));
      print(temp);
      dates.add(DateFormat('yyyy-MM-dd').parse(d.docs[i].id));
      events2.add({DateFormat('yyyy-MM-dd').parse(d.docs[i].id):List.generate(
          temp.length, (index) => Event(temp[index]["Event"],temp[index]["users"]," "," "))});
    }
    Map<DateTime,List<Event>> k = Map.fromIterable(List.generate(events2.length, (index) => index),
      key: (i){
        return dates[i];
        },
      value: (i)=> events2[i][dates[i]]);
    print(k);
    kEvents = LinkedHashMap<DateTime, List<Event>>(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll(k);
    print("added successfully");
  }

  @override
  void initState() {
    super.initState();
    getEventData();
      _selectedDay = _focusedDay;
      _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {
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
  Future sendReminders(DateTime d) async{
    var s =await databaseReference.collection('Users').doc(Auth()
        .getCurrentUser()
        .uid).get();
    if (s.exists) {
      s.get( DateFormat('yyyy-MM-dd').format(_focusedDay));
    }
  }
  Future setEvents() async {
    print("lol");
    List<Event>temp =(kEvents[_selectedDay]);
    for(int i=0;i<temp.length;i++){
      events.add({
        "Event":temp[i].title??" ",
        "description":temp[i].desc??" ",
        "time":temp[i].timer??TimeOfDay.now(),
        "users": temp[i].users??[],
      });
    }
    events.add({
      "Event": event.text,
      "description": desc.text,
      "time":timer.text,
      "users": emails
    });
    final users = await databaseReference.collection("Users").where("email",arrayContains: emails).get();
    final snapShot = databaseReference.collection('Users').doc(Auth()
        .getCurrentUser()
        .uid).collection("Events").doc(DateFormat('yyyy-MM-dd').format(_selectedDay));
    var data = await snapShot.get();
    if(data.exists){
    snapShot.update({
    'EventList': events
    });
    print('Event Added');
    }
    else{
      snapShot.set({
        'EventList': events
      });
      print('Event Added');
    }
  }
  Future<String> showPicker() async {
    TimeOfDay initialTime = TimeOfDay.now();
     TimeOfDay t = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (BuildContext context, Widget child) {
          return child;
        }
    );
     String res = t.hour.toString()+":"+t.minute.toString();
     return res;
  }

   static const _actionTitles = ['Create an event', 'Send reminders'];
   void _showAction(BuildContext context, int index) {
     showDialog<void>(
       context: context,
       builder: (context) {
         return AlertDialog(
           content:SingleChildScrollView(
             physics: AlwaysScrollableScrollPhysics(),
             child: Container(
               height: MediaQuery.of(context).size.height/2,
               child: Column(
                 children: [
                   IgnorePointer(
                     child: MyTextFieldDatePicker(
                       prefixIcon: Icon(Icons.calendar_today_rounded),
                       firstDate: kFirstDay,
                       lastDate: kLastDay,
                       initialDate: _selectedDay, onDateChanged: (DateTime value) {
                         if(mounted)
                         setState(() {
                           eventDate =value;
                         });
                         print(eventDate);
                     },
                     ),
                   ),
                   SizedBox( height: 8),
                   TextField(
                     onTap: (){
                       setState(() {
                          showPicker().then((value) => timer.text = value);
                       });
                     },
                     controller: timer,
                     decoration: InputDecoration(
                       border: OutlineInputBorder(),
                       labelText: "Time",
                       hintText: "Enter Time"
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
                   Expanded(child: EmailInput(parentEmails: emails,))
                 ],
               ),
             ),
           ),
           title:  Text(_actionTitles[index]),
           actions: [
             TextButton(
               onPressed: (){
                 event.clear();
                 desc.clear();
                 Navigator.of(context).pop();
                 },
               child: const Text('CANCEL',style:TextStyle(color: Colors.red),),
             ),
             TextButton(
               onPressed: (){
                 print(emails);
                 setEvents().whenComplete(() {//getEventData();
                   event.clear();
                   desc.clear();
                   Navigator
                       .of(context)
                       .pushReplacement(new MaterialPageRoute(builder: (BuildContext context) {
                     return new CalendarPage();
                   }));
                 });
               },
               child: const Text('OK'),),
           ],
         );
       },
     );
   }
   signout()async {
     Auth().signOut();
     Navigator
         .of(context)
         .push(new MaterialPageRoute(builder: (BuildContext context) {
       return  LogInPage();
     }));
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

          Container(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Username : ${Auth().getCurrentUser().displayName}",style: TextStyle(
                  fontSize: 20,
                ),),
                ElevatedButton(onPressed: (){
                  signout();
                },
                    style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all(Colors.black),
                      backgroundColor: MaterialStateProperty.all( Color.fromRGBO(255, 197, 1, 1)),
                    ),
                    child: Text("Log Out")),
              ],
            ),
          ),
          Divider(thickness: 2,),
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
              outsideDaysVisible: true,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false
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
          )
        ],
      ),
    );
  }
}