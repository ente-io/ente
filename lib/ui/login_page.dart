import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/web_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _config = Configuration.instance;
  String _email;

  @override
  void initState() {
    _email = _config.getEmail();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "sign in",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
          child: TextFormField(
            decoration: InputDecoration(
              hintText: 'email',
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
            autofocus: true,
          ),
        ),
        Padding(padding: EdgeInsets.all(8)),
        Padding(
          padding: const EdgeInsets.all(12),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "by clicking sign in, I agree to the ",
                ),
                TextSpan(
                  text: "terms of service",
                  style: TextStyle(
                    color: Colors.blue,
                    fontFamily: 'Ubuntu',
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) {
                            return WebPage("terms", "https://ente.io/terms");
                          },
                        ),
                      );
                    },
                ),
                TextSpan(text: " and "),
                TextSpan(
                  text: "privacy policy",
                  style: TextStyle(
                    color: Colors.blue,
                    fontFamily: 'Ubuntu',
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) {
                            return WebPage(
                                "privacy", "https://ente.io/privacy");
                          },
                        ),
                      );
                    },
                ),
              ],
              style: TextStyle(
                height: 1.25,
                fontSize: 12,
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
            onPressed: _email != null && _email.isNotEmpty
                ? () {
                    if (!isValidEmail(_email)) {
                      showErrorDialog(context, "invalid email address",
                          "please enter a valid email address.");
                      return;
                    }
                    _config.setEmail(_email);
                    UserService.instance.getOtt(context, _email);
                  }
                : null,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
