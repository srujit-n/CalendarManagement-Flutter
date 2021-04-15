import 'dart:collection';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter/material.dart';

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

final kNow = DateTime.now();
final kFirstDay = DateTime(kNow.year, 1, 1);
final kLastDay = DateTime(kNow.year + 1, 1, 1);

abstract class Functions {
  Future sendEmail(String s);
  Future<List> eventUsers(List w);
  int calculateDifference(DateTime date);
}

class FunctionUtils implements Functions {
  final databaseRef = FirebaseFirestore.instance.collection("Users").doc(Auth()
      .getCurrentUser()
      .uid).get();

  Future sendEmail(String s) async {
    String username = 'calendarpesurr@gmail.com';
    String password = 'pesurr%^&*';
    final smtpServer = gmail(username, password);
    // Create our message.
    final message = Message()
      ..from = Address(username, 'Your CalendarApp')
      ..recipients.add(s)
      ..subject = 'Event Reminder :: 😀 :: ${DateTime.now()}'
      ..html = "<h1>Reminder</h1>\n<p>This is to remind to attend the event scheduled with you .</p>";
    try {
      final sendReport = await send(message, smtpServer);
      showSimpleNotification(Text(sendReport.toString()),
          background: Color(0xff29a39d));

    } on MailerException catch (e) {
      showSimpleNotification(Text(e.toString()),
          background: Color(0xff29a39d));
    }
  }
  int calculateDifference(DateTime date) {
    DateTime now = DateTime.now();
    return DateTime(date.year, date.month, date.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  }
  Future<List> eventUsers(List w) async {
    List temp = [];
    final users = await FirebaseFirestore.instance.collection("Users").get();
    for (int i = 0; i < users.docs.length; i++) {
      var t = users.docs[i].get("Email");
      if (w.contains(t)) {
        temp.add(users.docs[i].id);
      }
    }
    return temp;
  }


  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }
}