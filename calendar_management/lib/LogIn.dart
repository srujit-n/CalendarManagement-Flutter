import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:calendar_management/auth.dart';
import 'package:overlay_support/overlay_support.dart';
import 'calendar.dart';

  final databaseReference = FirebaseFirestore.instance;

class LogInPage extends StatefulWidget {

  @override
  _LogInPageState createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  //final formKey = GlobalKey<FormState>();
  double height;
  double width;
  bool loading = false;
  bool newAccount = false;
  bool isFirstName = false;
  String signInBtnText = "LOGIN";
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController firstName = TextEditingController();
  FocusNode emailFocus = new FocusNode();
  FocusNode passwordFocus = new FocusNode();
  FocusNode nameFocus = new FocusNode();
  bool emailChecked = false;
  @override
  void initState() {
    emailFocus.addListener(() {
      if (emailFocus.hasFocus == false) {
        emailChecked = emailControl();
      }
    });
    passwordFocus.addListener(() {
      if (!emailControl()) {
        emailFocus.requestFocus();
      }
    });
    super.initState();
  }

  bool emailControl() {
    if (!emailChecked) {
      setState(() {
        if (email.text.length == 0) {
          showSimpleNotification(Text("Please enter an email ID"),
              background: Color(0xff29a39d));
          return false;
        } else {
          RegExp emailCheck = new RegExp(
              r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");
          if (emailCheck.hasMatch(email.text)) {
            loading = true;
            Auth().emailLoginMethods(email.text).then((loginMethods) {
              setState(() {
                loading = false;
              });
              if (loginMethods.isEmpty) {
                newAccount = true;
                signInBtnText = "Sign Up";
              } else {
                if (loginMethods.indexOf("password") == -1) {
                  if (loginMethods.contains("google.com")) {
                    googleSignIn();
                  }
                  else {
                    showSimpleNotification(
                        Text(
                            "Email and Password is not registered for this email ID. Please use " +
                                loginMethods
                                    .toString()), //TODO: Clean up output
                        background: Color(0xff29a39d));
                    Navigator.pop(context);
                  }
                } else {
                  newAccount = false;
                  signInBtnText = "Sign In";
                }
              }
            });
            return true;
          } else {
            setState(() {
              loading = false;
            });
            showSimpleNotification(Text("Please enter a valid email ID"),
                background: Color(0xff29a39d));
            return false;
          }
        }
      });
    } else {
      return true;
    }
  }

  void googleSignIn() {
    Auth().signInWithGoogle().then((user) {
      checkIfExists(user);
    });
  }

  void checkIfExists(User user) async {
    final snapShot =
    await databaseReference.collection('Users').doc(user.uid).get();
    if (snapShot == null || !snapShot.exists) {
      DocumentReference newData =
      databaseReference.collection("Users").doc(user.uid);
      newData.set({'Name': user.displayName, 'Email': user.email});
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => TableEventsExample(),
            settings: RouteSettings(name: 'Profile Creation')),
            (Route<dynamic> route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) =>  TableEventsExample(),
            settings: RouteSettings(name: 'Dashboard')),
            (Route<dynamic> route) => false,
      );
    }
  }

  void controlSignUp() async {
    if (newAccount) {
      User user;
      try {
        user =
        await Auth().signUp(email.text, password.text, firstName.text);
        final snapShot =
        await databaseReference.collection('Users').doc(user.uid).get();
        if (snapShot == null || !snapShot.exists) {
          DocumentReference newData =
          databaseReference.collection("Users").doc(user.uid);
          newData.set({'Name': user.displayName, 'Email': user.email});
          print('Signed up:' + user.uid);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) =>  TableEventsExample(),
                settings: RouteSettings(name: 'Dashboard')),
                (Route<dynamic> route) => false,
          );
        } else {
          print("User data already exists but User does not");
        }
      } catch (e) {
        print("Error");
        showSimpleNotification(Text(e.message), background: Color(0xff29a39d));
      }
    } else {
      User user;
      try {
        user = await Auth().signIn(email.text, password.text);
        print('Signed in:' + user.uid);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => TableEventsExample(),
              settings: RouteSettings(name: 'Dashboard')),
              (Route<dynamic> route) => false,
        );
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;

    return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                height: 0.1 * height,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                      padding:
                      EdgeInsets.only(left: 0.08 * width, bottom: 0.02 * width),
                      child: Text("Log IN",
                          textAlign: TextAlign.center)),
                ],
              ),
              Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
                Container(
                    margin: EdgeInsets.only(left: 0.085 * width),
                    padding: EdgeInsets.all(0.083 * width),
                    width: 0.098 * width,
                    height: 0.004 * height,
                    decoration: BoxDecoration(color: Color(0xffffc501)))
              ]),
              Container(height: 0.09 * height),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    child: Text("Login using social media",
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
              Container(height: 0.04 * height),
              Center(
                child: Container(
                  margin: EdgeInsets.only(left: 0.08 * width),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(width)),
                      color: Colors.grey[200]),
                  child: IconButton(
                      iconSize: height / 80,
                      icon: new SvgPicture.asset('assets/images/google.svg'),
                      onPressed: googleSignIn),
                ),
              ),
              Container(
                height: 0.05 * height,
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("OR",

                      textAlign: TextAlign.center),
                ],
              ),
              Container(
                height: 0.05 * height,
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("Login with Email",

                      textAlign: TextAlign.center),
                ],
              ),
              Container(
                height: 0.04 * height,
              ),
              Row(
                children: <Widget>[
                  Container(
                      padding: EdgeInsets.only(
                          left: 0.08 * width, bottom: 0.004 * height),
                      child: Text(
                        "Email ID",
                      )),
                ],
              ),
              //here
              Container(
                height: 0.05 * height,
                width: width,
                margin: EdgeInsets.only(right: 0.08 * width, left: 0.08 * width),
                child: TextField(
                  focusNode: emailFocus,
                  controller: email,
                  decoration: new InputDecoration(
                    // labelText: 'Email',
                    contentPadding: EdgeInsets.fromLTRB(1, 0, 0, 4),
                    fillColor: Color(0xff131415),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xffB8C0CC),
                        )),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: const Color(0xff29a39d), style: BorderStyle.solid),
                    ),
                    suffix: loading
                        ? CircularProgressIndicator()
                        : IconButton(
                        icon: Icon(
                          Icons.check,
                          color: const Color(0xff29a39d),
                        ),
                        onPressed: emailControl),
                  ),
                ),
              ),

              Container(
                height: 0.040 * height,
              ),
              Row(
                children: <Widget>[
                  Container(
                      padding: EdgeInsets.only(left: 0.08 * width),
                      child: Text(
                        "Password",
                      )),
                ],
              ),
              Container(
                height: 0.05 * height,
                width: width,
                margin: EdgeInsets.only(right: 0.08 * width, left: 0.08 * width),
                child: TextField(
                  focusNode: passwordFocus,
                  controller: password,
                  decoration: new InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(1, 0, 0, 4),
                    fillColor: Color(0xff131415),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xffB8C0CC),
                        )),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: const Color(0xff29a39d), style: BorderStyle.solid),
                    ),
                  ),
                ),
              ),

              Container(
                height: 0.04 * height,
              ),
              Visibility(
                visible:newAccount,
                child:
                Row(
                  children: <Widget>[
                    Container(
                        padding: EdgeInsets.only(left: 0.08 * width),
                        child: Text(
                          "Name",
                        )),
                  ],
                ),
              ),
              Visibility(
                visible:newAccount,
                child:
                Container(
                  height: 0.05 * height,
                  width: width,
                  margin: EdgeInsets.only(right: 0.08 * width, left: 0.08 * width),
                  child: TextField(
                    focusNode: nameFocus,
                    controller: firstName,
                    decoration: new InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(1, 0, 0, 4),
                      fillColor: Color(0xff131415),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xffB8C0CC),
                          )),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: const Color(0xff29a39d), style: BorderStyle.solid),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 0.04 * height,
              ),
              Container(
                  child: FlatButton(
                      onPressed: controlSignUp,
                      child: Container(
                          width: 0.85 * width,
                          height: 0.07 * height,
                          decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.all(Radius.circular(width / 30)),
                              color: const Color(0xffffc501)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(signInBtnText,
                                )
                              ])))),
            ],
          ),
        ));
  }
}
