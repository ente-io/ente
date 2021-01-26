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
        title: Text("verify email"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "we've sent a mail to",
                style: TextStyle(fontSize: 18),
              ),
              Padding(padding: EdgeInsets.all(2)),
              Text(
                Configuration.instance.getEmail(),
                style: TextStyle(
                  color: Theme.of(context).accentColor,
                  fontSize: 18,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "please check your inbox (and spam) to complete verification.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(60, 0, 60, 32),
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: 'tap to enter code',
                    contentPadding: EdgeInsets.all(12),
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
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(60, 0, 60, 0),
                width: double.infinity,
                height: 64,
                child: button(
                  "verify",
                  onPressed: _verificationCodeController.text == null ||
                          _verificationCodeController.text.isEmpty
                      ? null
                      : () {
                          UserService.instance.getCredentials(
                              context, _verificationCodeController.text);
                        },
                  fontSize: 18,
                ),
              ),
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
                    "did not get email?",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
