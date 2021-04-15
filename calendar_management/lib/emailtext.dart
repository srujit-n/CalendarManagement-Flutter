import 'package:flutter/material.dart';

class EmailInput extends StatefulWidget {
  final Function setList;
  final String hint;
  final List<String> parentEmails;

  const EmailInput({Key key, this.setList, this.hint, this.parentEmails}) : super(key: key);

  @override
  _EmailInputState createState() => _EmailInputState();
}

class _EmailInputState extends State<EmailInput> {
  TextEditingController _emailController;
  String lastValue = '';
  List<String> emails = [];
  FocusNode focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    emails.addAll(widget.parentEmails);
    focus.addListener(() {
      if (!focus.hasFocus) {
        updateEmails();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Center(
          child: Column(
            children: <Widget>[
              Container(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: <Widget>[
                      ...emails
                          .map(
                            (email) => Chip(
                          avatar: CircleAvatar(
                            backgroundColor: Colors.black,
                            child: Text(
                              email.substring(0, 1),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          labelPadding: EdgeInsets.all(4),
                          backgroundColor: Color.fromRGBO(255, 197, 1, 1),
                          label: Text(
                            email,
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          onDeleted: () => {
                            setState(() {
                              emails.removeWhere((element) => email == element);
                            })
                          },
                        ),
                      )
                          .toList(),
                    ],
                  ),
                ),
              ),
              TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    hintText: widget.hint),
                controller: _emailController,
                focusNode: focus,
                onChanged: (String val) {
                  setState(() {
                    if (val != lastValue) {
                      lastValue = val;
                      if (val.endsWith(' ') && validateEmail(val.trim())) {
                        if (!emails.contains(val.trim())) {
                          emails.add(val.trim());
                          widget.setList(emails);
                        }
                        _emailController.clear();
                      } else if (val.endsWith(' ') && !validateEmail(val.trim())) {
                        _emailController.clear();
                      }
                    }
                  });
                },
                onEditingComplete: () {
                  updateEmails();
                },
                onSubmitted:(e){
                  focus.nextFocus();
                },
              )
            ],
          ),
        ));
  }

  updateEmails() {
    setState(() {
      if (validateEmail(_emailController.text)) {
        if (!emails.contains(_emailController.text)) {
          emails.add(_emailController.text.trim());
          print(emails);
          widget.setList(emails);
        }
        _emailController.clear();
      } else if (!validateEmail(_emailController.text)) {
        _emailController.clear();
      }
    });
  }

  setEmails(List<String> emails) {
    this.emails = emails;
  }
}

bool validateEmail(String value) {
  Pattern pattern =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  RegExp regex = new RegExp(pattern);
  return regex.hasMatch(value);
}