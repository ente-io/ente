import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myapp/core/configuration.dart';
import 'package:myapp/user_authenticator.dart';

class SignInWidget extends StatefulWidget {
  final Function() onReconfigurationRequested;

  const SignInWidget(
    this.onReconfigurationRequested, {
    Key key,
  }) : super(key: key);

  @override
  _SignInWidgetState createState() => _SignInWidgetState();
}

class _SignInWidgetState extends State<SignInWidget> {
  String _username, _password;
  @override
  void initState() {
    _username = Configuration.instance.getUsername();
    _password = Configuration.instance.getPassword();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
      children: <Widget>[
        TextFormField(
          initialValue: _username,
          decoration: InputDecoration(
            hintText: 'username',
            contentPadding: EdgeInsets.all(20),
          ),
          autofocus: true,
          autocorrect: false,
          onChanged: (value) {
            setState(() {
              _username = value;
            });
          },
        ),
        TextFormField(
          initialValue: _password,
          decoration: InputDecoration(
            hintText: 'password',
            contentPadding: EdgeInsets.all(20),
          ),
          autocorrect: false,
          obscureText: true,
          onChanged: (value) {
            setState(() {
              _password = value;
            });
          },
        ),
        CupertinoButton(
          child: Text("Sign In"),
          onPressed: () async {
            final loggedIn =
                await UserAuthenticator.instance.login(_username, _password);
            if (loggedIn) {
              Navigator.of(context).pop();
            } else {
              _showErrorDialog();
            }
          },
        ),
      ],
    ));
  }

  void _showErrorDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Login failed'),
          content: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: Text(
                'Please make sure that the credentials entered are correct.'),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text('Reconfigure'),
              onPressed: () {
                Navigator.of(context).pop();
                Configuration.instance.setEndpoint(null);
                widget.onReconfigurationRequested();
              },
            ),
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
