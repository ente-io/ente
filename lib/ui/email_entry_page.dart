import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photos/user_authenticator.dart';

class EmailEntryPage extends StatefulWidget {
  final String email;

  EmailEntryPage({this.email, Key key}) : super(key: key);

  @override
  _EmailEntryPageState createState() => _EmailEntryPageState();
}

class _EmailEntryPageState extends State<EmailEntryPage> {
  String _email;

  @override
  void initState() {
    _email = widget.email;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Preserve Memories"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            SvgPicture.asset(
              "assets/around_the_world.svg",
              width: 256,
              height: 256,
            ),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'email@domain.com',
                contentPadding: EdgeInsets.all(20),
              ),
              initialValue: widget.email == null ? "" : widget.email,
              autofocus: true,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              onChanged: (email) {
                log(email);
                setState(() {
                  _email = email;
                });
              },
            ),
            Padding(padding: EdgeInsets.all(8)),
            SizedBox(
                width: double.infinity,
                child: RaisedButton(
                  onPressed: () {
                    UserAuthenticator.instance.getOtt(context, _email);
                  },
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                  child: Text("Sign In"),
                  color: Theme.of(context).buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
