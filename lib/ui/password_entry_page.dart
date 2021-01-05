import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_password_strength/flutter_password_strength.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/utils/dialog_util.dart';

class PasswordEntryPage extends StatefulWidget {
  PasswordEntryPage({Key key}) : super(key: key);

  @override
  _PasswordEntryPageState createState() => _PasswordEntryPageState();
}

class _PasswordEntryPageState extends State<PasswordEntryPage> {
  final _passwordController1 = TextEditingController(),
      _passwordController2 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.lock),
        title: Text("encryption password"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return Column(
      children: [
        FlutterPasswordStrength(
          password: _passwordController1.text,
          backgroundColor: Colors.grey[850],
          strengthCallback: (strength) {
            debugPrint(strength.toString());
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 36, 16, 16),
              child: Column(
                children: [
                  // Image.asset(
                  //   "assets/vault.png",
                  //   width: 196,
                  //   height: 196,
                  // ),
                  Padding(padding: EdgeInsets.all(12)),
                  Text(
                    "enter a password we can use to encrypt your data",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.3,
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(8)),
                  Text("we don't store this password, so if you forget, "),
                  Text.rich(
                    TextSpan(
                        text: "we cannot decrypt your data",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        )),
                    style: TextStyle(
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Padding(padding: EdgeInsets.all(12)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: "password",
                        contentPadding: EdgeInsets.all(20),
                      ),
                      controller: _passwordController1,
                      autofocus: false,
                      autocorrect: false,
                      keyboardType: TextInputType.visiblePassword,
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(8)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: "password again",
                        contentPadding: EdgeInsets.all(20),
                      ),
                      controller: _passwordController2,
                      autofocus: false,
                      autocorrect: false,
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(16)),
                  Container(
                      width: double.infinity,
                      height: 44,
                      padding: EdgeInsets.fromLTRB(32, 0, 32, 0),
                      child: button(
                        "set password",
                        onPressed: _passwordController1.text.isNotEmpty &&
                                _passwordController2.text.isNotEmpty
                            ? () {
                                if (_passwordController1.text !=
                                    _passwordController2.text) {
                                  showErrorDialog(context, "Uhm...",
                                      "The passwords you entered don't match.");
                                } else {
                                  _showPasswordConfirmationDialog();
                                }
                              }
                            : null,
                      )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPasswordConfirmationDialog() {
    AlertDialog alert = AlertDialog(
      title: Text("Confirmation"),
      content: SingleChildScrollView(
        child: Column(children: [
          Text("The password you are promising to never forget is"),
          Padding(padding: EdgeInsets.all(8)),
          Text(_passwordController1.text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
              )),
        ]),
      ),
      actions: [
        FlatButton(
          child: Text("Change"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: Text("Confirm"),
          onPressed: () {
            Navigator.of(context).pop();
            UserService.instance
                .setupAttributes(context, _passwordController1.text);
          },
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
