import 'dart:collection';
import 'package:calendar_management/LogIn.dart';
import 'package:calendar_management/emailtext.dart';
import 'package:calendar_management/utils.dart';
import 'package:calendar_management/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:table_calendar/table_calendar.dart';
import 'auth.dart';
import 'datepicker.dart';

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
  List<Map<DateTime,List<Event>>> events2=[];
  TextEditingController event = TextEditingController();
  TextEditingController timer = TextEditingController();
  TextEditingController desc = TextEditingController();
  DateTime _selectedDay;
  RegExp time = new RegExp(r"^(00|0[0-9]|1[0-9]|2[0-4]):[0-5][0-9]$");
  List tapTitles = ["Are you sure you want to delete the event?","Are you sure you want to send  the event reminders?"];
  Timestamp t;
  DateTime eventDate = DateTime.now();
  Map res = Map();
  Future<void> getEventData(String s) async{
    var d = await databaseReference.collection("Users").doc(s).collection("Events").get();
    List<DateTime>dates=[];
    events2=[];
    for(int i=0;i<d.docs.length;i++){
      List temp = (d.docs[i].get("EventList"));
      print(temp);
      dates.add(DateFormat('yyyy-MM-dd').parse(d.docs[i].id));
      events2.add({DateFormat('yyyy-MM-dd').parse(d.docs[i].id):List.generate(
          temp.length, (index) => Event(temp[index]["Event"],temp[index]["users"],temp[index]["description"],temp[index]["time"],temp[index]["CreatedBy"]))});
    }
    Map<DateTime,List<Event>> k = Map.fromIterable(List.generate(events2.length, (index) => index),
      key: (i){
        return dates[i];
        },
      value: (i)=> events2[i][dates[i]]);
    print(k);
    kEvents = LinkedHashMap<DateTime, List<Event>>(
      equals: isSameDay,
      hashCode: FunctionUtils().getHashCode,
    )..addAll(k);
    print("added successfully");
  }

  @override
  void initState() {
    super.initState();
    getEventData(Auth().getCurrentUser().uid);
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
  Future setEvents() async {
    List temp = await FunctionUtils().eventUsers(emails);
    int today = FunctionUtils().calculateDifference(_selectedDay);
    if(today<0){
      showSimpleNotification(Text("You cannot create a event before today!"));
    }
    else {
      for (int i = 0; i < temp.length; i++) {
        List events = [];
        print("lol");
        events.add({
          "Event": event.text,
          "description": desc.text,
          "time": timer.text,
          "CreatedBy": emails[0],
          "users": emails
        });
        final sp = await databaseReference.collection('Users')
            .doc(temp[i])
            .get();
        String name = sp.get("Name");
        String email = sp.get("Email");
        final snapShot = databaseReference.collection('Users')
            .doc(temp[i])
            .collection("Events")
            .doc(
            DateFormat('yyyy-MM-dd').format(_selectedDay));
        var data = await snapShot.get();
        int max = !data.exists ? 0 : data
            .get("EventList")
            .length;
        if (max <= 3) {
          if (data.exists) {
            snapShot.update({"EventList": FieldValue.arrayUnion(events)});
            showSimpleNotification(
                Text(
                  "Event Added"),background: Color(0xff29a39d)
            );
            FunctionUtils().sendEmail(email);
          }
          else {
            snapShot.set({
              'EventList': events
            });
            showSimpleNotification(
                Text(
                  "Event Added",),background: Color(0xff29a39d)
            );
            FunctionUtils().sendEmail(email);
          }
        }
        else {
          showSimpleNotification(
            Text(
              "$name isn't available",),background: Color(0xff29a39d)
          );
          break;
        }
      }
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
    String res = t.format(context);
    return res;

  }
  void _TapEvents(Event e ,int i){
    showDialog(context: context, builder:(context){
      return AlertDialog(
          title: Text(tapTitles[i]),
          actions: [
        TextButton(
          onPressed: ()=> Navigator.of(context).pop(),
          child: const Text('Cancel',style:TextStyle(color: Colors.red),),
        ),
        TextButton(
          onPressed: () async{
            if(i==0) {
              List users  =await FunctionUtils().eventUsers(e.users);
              print(users);
              Map temp = {
                "CreatedBy": e.creator,
                "Event": e.title,
                "description": e.desc,
                "time": e.timer,
                "users": e.users
              };
              for(int i=0;i<users.length;i++){
                final snapshot = databaseReference.collection('Users')
                    .doc(users[i])
                    .collection("Events")
                    .doc(
                    DateFormat('yyyy-MM-dd').format(_selectedDay));
                await snapshot.get().then((value){
                  List events = value.data()["EventList"];
                  print(events);
                  events.removeWhere((element){
                    if(element["time"]==temp["time"]){
                      return true;
                    }
                    return false;
                  });
                  print(events);
                 snapshot.update({"EventList":events});
                });
              }

                  Navigator
                      .of(context)
                      .pushReplacement(
                      new MaterialPageRoute(builder: (BuildContext context) {
                        return new CalendarPage();
                      }));
            }
            else{
              for(int i=0;i<e.users.length;i++){
                FunctionUtils().sendEmail(e.users[i]);
              }
            }
          },
          child: const Text('Yes'),),
      ]
      );
    });
  }

   static const _actionTitle = 'Create an event';
   void _showAction(BuildContext context) {
     showDialog<void>(
       context: context,
       builder: (context) {
         return AlertDialog(
           content:SingleChildScrollView(
             physics: AlwaysScrollableScrollPhysics(),
             child: Container(
               width: MediaQuery.of(context).size.width,
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
                   Container(
                     width: MediaQuery.of(context).size.width,
                       child: EmailInput(parentEmails: emails,setList: (e){
                            setState(() {
                              emails=e;
                            });
                   },))
                 ],
               ),
             ),
           ),
           title:  Text(_actionTitle),
           actions: [
             TextButton(
               onPressed: (){
                 event.clear();
                 desc.clear();
                 timer.clear();
                 Navigator.of(context).pop();
                 },
               child: const Text('CANCEL',style:TextStyle(color: Colors.red),),
             ),
             TextButton(
               onPressed: () {
                 if(timer.text.isEmpty || !(time.hasMatch(timer.text))){
                   showSimpleNotification(Text("Please enter a valid time to the event"));
                 }
                 else if(event.text.isEmpty){
                   showSimpleNotification(Text("Please enter a valid title to the event"));
                 }
                 else if(desc.text.isEmpty){
                   showSimpleNotification(Text("Please enter description to the event"));
                 }
                 else{
                 print(emails);
                 setEvents().whenComplete(() {
                 event.clear();
                 desc.clear();
                 Navigator
                     .of(context)
                     .pushReplacement(new MaterialPageRoute(builder: (BuildContext context) {
                 return new CalendarPage();
                 }));
                 });
                 }
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromRGBO(255, 197, 1, 1),
        onPressed: () => _showAction(context),
        child:Icon(Icons.event_note_rounded,color: Colors.black,),
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
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        onLongPress: (){
                          if(value[index].creator==emails[0]){
                            _TapEvents(value[index], 0);
                          }
                          else{
                            showSimpleNotification(Text("You can't delete event since you aren't the owner of it"),
                                background: Color(0xff29a39d));
                          }
                        },
                        onTap: () {
                          if(value[index].creator==emails[0]){
                            _TapEvents(value[index], 1);
                          }
                          else{
                            showSimpleNotification(Text("You can't send reminders since you didn't create the event"),
                                background: Color(0xff29a39d));
                          }
                        },
                        leading: Text((index+1).toString(),style: TextStyle(color: Color.fromRGBO(255, 197, 1, 1)),),
                        title: Text('${value[index].title}',style: TextStyle(color: Color.fromRGBO(255, 197, 1, 1)),),
                        subtitle: Text(value[index].desc,style: TextStyle(color: Color.fromRGBO(255, 197, 1, 1)),),
                        trailing: Text(value[index].timer,style: TextStyle(color: Color.fromRGBO(255, 197, 1, 1)),),
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