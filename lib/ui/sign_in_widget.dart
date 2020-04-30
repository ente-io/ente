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
  String _username, _password, _repeatedPassword;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (Configuration.instance.getToken() == null) {
      // Has probably not signed up
      return _getSignUpWidget(context);
    } else {
      return _getSignInWidget(context);
    }
  }

  Widget _getSignUpWidget(BuildContext context) {
    return Container(
        child: Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
          child: Text("Create an account to get started"),
        ),
        TextFormField(
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
        TextFormField(
          decoration: InputDecoration(
            hintText: 'repeat password',
            contentPadding: EdgeInsets.all(20),
          ),
          autocorrect: false,
          obscureText: true,
          onChanged: (value) {
            setState(() {
              _repeatedPassword = value;
            });
          },
        ),
        CupertinoButton(
          child: Text("Sign Up"),
          onPressed: () async {
            if (_password != _repeatedPassword) {
              _showPasswordMismatchDialog();
            } else {
              try {
                final userCreated = await UserAuthenticator.instance
                    .create(_username, _password);
                if (userCreated) {
                  Navigator.of(context).pop();
                } else {
                  _showGenericErrorDialog();
                }
              } catch (e) {
                _showGenericErrorDialog(error: e);
              }
            }
          },
        ),
      ],
    ));
  }

  Widget _getSignInWidget(BuildContext context) {
    return Container(
        child: Column(
      children: <Widget>[
        TextFormField(
          initialValue: Configuration.instance.getUsername(),
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
          initialValue: Configuration.instance.getPassword(),
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
              _showAuthenticationFailedErrorDialog();
            }
          },
        ),
      ],
    ));
  }

  void _showPasswordMismatchDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text("Passwords don't match"),
          content: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
            child: Text("Please make sure that the passwords you enter match."),
          ),
          actions: <Widget>[
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

  void _showGenericErrorDialog({Exception error}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text("Ooops."),
          content: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
            child: error == null
                ? Text("Something went wrong.")
                : Text(error.toString()),
          ),
          actions: <Widget>[
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

  void _showAuthenticationFailedErrorDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Login failed'),
          content: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
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
