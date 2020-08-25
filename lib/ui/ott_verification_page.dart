import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photos/ui/email_entry_page.dart';
import 'package:photos/user_authenticator.dart';

class OTTVerificationPage extends StatefulWidget {
  final String email;
  OTTVerificationPage(this.email, {Key key}) : super(key: key);

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
        padding: EdgeInsets.fromLTRB(8, 64, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SvgPicture.asset(
              "assets/email_sent.svg",
              width: 256,
              height: 256,
            ),
            Padding(padding: EdgeInsets.all(12)),
            Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 18),
                children: <TextSpan>[
                  TextSpan(text: "We've sent a mail to "),
                  TextSpan(
                      text: widget.email,
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
            SizedBox(
                width: double.infinity,
                child: RaisedButton(
                  onPressed: _verificationCodeController.text == null ||
                          _verificationCodeController.text.isEmpty
                      ? null
                      : () {
                          UserAuthenticator.instance.getCredentials(context,
                              widget.email, _verificationCodeController.text);
                        },
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                  child: Text(
                    "Verify",
                  ),
                  color: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                )),
            Padding(padding: EdgeInsets.all(8)),
            TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return EmailEntryPage(email: widget.email);
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
