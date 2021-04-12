import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

import 'auth.dart';

/// Example event class.
class Event {
  final String title;
  final List users;
  final String desc;
  final String timer;
  final String creator;
  const Event( this.title, this.users,this.desc,this.timer,this.creator);

  @override
  String toString() => title;
}

final databaseRef = FirebaseFirestore.instance.collection("Users").doc(Auth().getCurrentUser().uid).get();
List users = List.generate(10, (index) => 'howdy');


int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

final kNow = DateTime.now();
final kFirstDay = DateTime(kNow.year, 1, 1);
final kLastDay = DateTime(kNow.year+1, 1, 1);