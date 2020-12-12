import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailEntryPage extends StatefulWidget {
  EmailEntryPage({Key key}) : super(key: key);

  @override
  _EmailEntryPageState createState() => _EmailEntryPageState();
}

class _EmailEntryPageState extends State<EmailEntryPage> {
  final _config = Configuration.instance;
  String _email;
  String _name;

  @override
  void initState() {
    _email = _config.getEmail();
    _name = _config.getName();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("sign in"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    final locale = Localizations.localeOf(context);
    var amount = "\$4";
    switch (locale.countryCode) {
      case "IN":
        amount = "₹249";
        break;
      case "US":
        amount = "\$4";
        break;
      default:
        amount = "€4";
    }

    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            // Image.asset(
            //   "assets/welcome.png",
            //   width: 300,
            //   height: 200,
            // ),
            Padding(
              padding: EdgeInsets.all(32),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: 'your name',
                  hintStyle: TextStyle(
                    color: Colors.white30,
                  ),
                  contentPadding: EdgeInsets.all(12),
                ),
                onChanged: (value) {
                  setState(() {
                    _name = value;
                  });
                },
                autofocus: true,
                autocorrect: false,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                initialValue: _name,
              ),
            ),
            Padding(padding: EdgeInsets.all(8)),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: 'you@email.com',
                  hintStyle: TextStyle(
                    color: Colors.white30,
                  ),
                  contentPadding: EdgeInsets.all(12),
                ),
                onChanged: (value) {
                  setState(() {
                    _email = value;
                  });
                },
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                initialValue: _email,
              ),
            ),
            Padding(padding: EdgeInsets.all(20)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: Colors.grey[700],
                  padding: EdgeInsets.all(24),
                  child: Row(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.info),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(12, 0, 0, 0),
                      ),
                      Expanded(
                        child: Text(
                            "ente will be free to use until we have launched a stable web client. After that it will cost $amount/100GB monthly. We'll make sure it's worth it.",
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              color: Colors.white70,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: EdgeInsets.all(8)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "By clicking Sign In, I agree to the ",
                    ),
                    TextSpan(
                      text: "Terms of Service",
                      style: TextStyle(
                        color: Colors.blue,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launch("https://ente.io/terms");
                        },
                    ),
                    TextSpan(text: " and "),
                    TextSpan(
                      text: "Privacy Policy",
                      style: TextStyle(
                        color: Colors.blue,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launch("https://ente.io/privacy");
                        },
                    ),
                    TextSpan(text: "."),
                  ],
                  style: TextStyle(
                    height: 1.25,
                    fontSize: 14,
                    fontFamily: 'Ubuntu',
                    color: Colors.white70,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(padding: EdgeInsets.all(8)),
            Container(
              width: double.infinity,
              height: 64,
              padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
              child: button(
                "sign in",
                onPressed: _email != null && _name != null
                    ? () {
                        if (!isValidEmail(_email)) {
                          showErrorDialog(context, "Invalid email address",
                              "Please enter a valid email address.");
                          return;
                        }
                        _config.setEmail(_email);
                        _config.setName(_name);
                        UserService.instance.getOtt(context, _email);
                      }
                    : null,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
