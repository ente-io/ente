import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';

class OTTVerificationPage extends StatefulWidget {
  final String email;
  final bool isChangeEmail;

  OTTVerificationPage(
    this.email, {
    this.isChangeEmail = false,
    Key key,
  }) : super(key: key);

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
                widget.email,
                style: TextStyle(
                  color: Theme.of(context).buttonColor,
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
              Padding(
                padding: EdgeInsets.all(12),
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
                          if (widget.isChangeEmail) {
                            UserService.instance.changeEmail(context,
                                widget.email, _verificationCodeController.text);
                          } else {
                            UserService.instance.verifyEmail(
                                context, _verificationCodeController.text);
                          }
                        },
                  fontSize: 18,
                ),
              ),
              Padding(padding: EdgeInsets.all(8)),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "did not get email?",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
