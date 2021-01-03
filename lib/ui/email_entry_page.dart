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
    final appBar = AppBar(
      title: Hero(
        tag: "sign_up_hero_text",
        child: Material(
          color: Colors.transparent,
          child: Text(
            "sign up",
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: appBar,
      body: _getBody(appBar.preferredSize.height),
    );
  }

  Widget _getBody(final appBarHeight) {
    var _pageSize = MediaQuery.of(context).size.height;
    var _notifySize = MediaQuery.of(context).padding.top;
    var _appBarSize = appBarHeight;
    return SingleChildScrollView(
      child: Container(
        height: _pageSize - (_appBarSize + _notifySize),
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
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
            Padding(padding: EdgeInsets.all(8)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "by clicking sign up, I agree to the ",
                    ),
                    TextSpan(
                      text: "terms of service",
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
                      text: "privacy policy",
                      style: TextStyle(
                        color: Colors.blue,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launch("https://ente.io/privacy");
                        },
                    ),
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
                "sign up",
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
            Expanded(child: Container()),
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return Container(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Text(
                                    'you can choose a pricing plan after signing up'),
                                Padding(padding: EdgeInsets.all(8)),
                                GestureDetector(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white38,
                                      ),
                                      Padding(padding: EdgeInsets.all(1)),
                                      Text(
                                        'close',
                                        style: TextStyle(
                                          color: Colors.white38,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () => Navigator.pop(context),
                                )
                              ],
                            ),
                          ),
                        );
                      });
                },
                child: Container(
                  padding: EdgeInsets.all(32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "pricing",
                      ),
                      Icon(Icons.arrow_drop_up),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
