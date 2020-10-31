import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/email_entry_page.dart';
import 'package:photos/services/user_service.dart';

class OTTVerificationPage extends StatefulWidget {
  OTTVerificationPage({Key key}) : super(key: key);

  @override
  _OTTVerificationPageState createState() => _OTTVerificationPageState();
}

class _OTTVerificationPageState extends State<OTTVerificationPage> {
  final _verificationCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Verify Email"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset(
              "assets/email_sent.png",
              width: 220,
              height: 220,
            ),
            Padding(padding: EdgeInsets.all(12)),
            Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 18),
                children: <TextSpan>[
                  TextSpan(text: "We've sent a mail to "),
                  TextSpan(
                      text: Configuration.instance.getEmail(),
                      style: TextStyle(
                        color: Theme.of(context).accentColor,
                      )),
                  TextSpan(text: "."),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            Padding(padding: EdgeInsets.all(12)),
            Text(
              "Please check your inbox (and spam) to complete verification.",
              textAlign: TextAlign.center,
            ),
            Padding(padding: EdgeInsets.all(12)),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Tap to enter verification code',
                contentPadding: EdgeInsets.all(20),
              ),
              controller: _verificationCodeController,
              autofocus: false,
              autocorrect: false,
              keyboardType: TextInputType.visiblePassword,
              textAlign: TextAlign.center,
              onChanged: (_) {
                setState(() {});
              },
            ),
            Padding(padding: EdgeInsets.all(8)),
            Container(
                width: double.infinity,
                height: 44,
                child: button(
                  "Verify",
                  onPressed: _verificationCodeController.text == null ||
                          _verificationCodeController.text.isEmpty
                      ? null
                      : () {
                          UserService.instance.getCredentials(
                              context, _verificationCodeController.text);
                        },
                )),
            Padding(padding: EdgeInsets.all(8)),
            FlatButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return EmailEntryPage();
                      },
                    ),
                  );
                },
                child: Text(
                  "Did not get email?",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 12,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
