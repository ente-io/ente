import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
          children: [
            SvgPicture.asset(
              "assets/email_sent.svg",
              width: 256,
              height: 256,
            ),
            Padding(padding: EdgeInsets.all(12)),
            Text.rich(
              TextSpan(
                text: "We've sent a mail to ",
                style: TextStyle(fontSize: 18),
                children: <TextSpan>[
                  TextSpan(
                      text: widget.email,
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                      )),
                  // can add more TextSpans here...
                ],
              ),
              textAlign: TextAlign.center,
            ),
            Padding(padding: EdgeInsets.all(12)),
            Text(
              "Please check your inbox (and spam folders) to complete the verification.",
              textAlign: TextAlign.center,
            ),
            Padding(padding: EdgeInsets.all(12)),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Tap to enter verification code',
                contentPadding: EdgeInsets.all(20),
              ),
              controller: _verificationCodeController,
              autofocus: true,
              autocorrect: false,
              keyboardType: TextInputType.visiblePassword,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
