import 'package:calendar_management/LogIn.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Import the firebase_core plugin
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';

import 'auth.dart';
import 'calendar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Future<FirebaseApp> _initialization = Firebase.initializeApp();
    Stream s = FirebaseAuth.instance.authStateChanges();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return FutureBuilder(
      // Initialize FlutterFire:
      future: _initialization,
      // ignore: missing_return
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return new Container(child: Text("Firebase went wrong"));
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {

          if (Auth().getCurrentUser() != null) {
            return OverlaySupport(
                child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    title: 'Near Vibe',
                    theme: ThemeData(
                      fontFamily: 'Nunito',
                      primaryColor: const Color(0xff29a39d),
                      accentColor: const Color(0xff29a39d),
                    ),
                    home: CalendarPage()));
          } else {
            return OverlaySupport(
                child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    title: 'Near Vibe',
                    theme: ThemeData(
                      fontFamily: 'Nunito',
                      primaryColor: const Color(0xff29a39d),
                      accentColor: const Color(0xff29a39d),
                    ),
                    home: LogInPage()));
          }
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return CircularProgressIndicator();
      },
    );
  }
}
