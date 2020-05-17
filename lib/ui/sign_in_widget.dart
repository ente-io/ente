import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/user_authenticator.dart';

class SignInWidget extends StatefulWidget {
  final Function() onReconfigurationRequested;

  const SignInWidget(
    this.onReconfigurationRequested, {
    Key key,
  }) : super(key: key);

  @override
  _SignInWidgetState createState() => _SignInWidgetState();
}

enum Mode { sign_up, sign_in, unknown }

class _SignInWidgetState extends State<SignInWidget> {
  Mode mode = Mode.unknown;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (mode == Mode.sign_up) {
      return _getSignUpWidget(context);
    } else {
      return _getSignInWidget(context);
    }
  }

  Widget _getSignUpWidget(BuildContext context) {
    return Container(
        child: SingleChildScrollView(
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
            controller: _usernameController,
            autofocus: true,
            autocorrect: false,
          ),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'password',
              contentPadding: EdgeInsets.all(20),
            ),
            autocorrect: false,
            obscureText: true,
            controller: _passwordController,
          ),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'repeat password',
              contentPadding: EdgeInsets.all(20),
            ),
            autocorrect: false,
            obscureText: true,
            controller: _repeatPasswordController,
          ),
          CupertinoButton(
            child: Text("Sign Up"),
            onPressed: () async {
              if (_passwordController.text != _repeatPasswordController.text) {
                _showPasswordMismatchDialog();
              } else {
                try {
                  final userCreated = await UserAuthenticator.instance.create(
                      _usernameController.text, _passwordController.text);
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
          CupertinoButton(
            child: Text("Have an account?"),
            onPressed: () {
              setState(() {
                mode = Mode.sign_in;
              });
            },
          ),
        ],
      ),
    ));
  }

  Widget _getSignInWidget(BuildContext context) {
    return Container(
        child: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextFormField(
            // initialValue: Configuration.instance.getUsername(),
            decoration: InputDecoration(
              hintText: 'username',
              contentPadding: EdgeInsets.all(20),
            ),
            autofocus: true,
            autocorrect: false,
            controller: _usernameController,
          ),
          TextFormField(
            // initialValue: Configuration.instance.getPassword(),
            decoration: InputDecoration(
              hintText: 'password',
              contentPadding: EdgeInsets.all(20),
            ),
            autocorrect: false,
            obscureText: true,
            controller: _passwordController,
          ),
          CupertinoButton(
            child: Text("Sign In"),
            onPressed: () async {
              final loggedIn = await UserAuthenticator.instance
                  .login(_usernameController.text, _passwordController.text);
              if (loggedIn) {
                Navigator.of(context).pop();
              } else {
                _showAuthenticationFailedErrorDialog();
              }
            },
          ),
          CupertinoButton(
            child: Text("Don't have an account?"),
            onPressed: () {
              setState(() {
                mode = Mode.sign_up;
              });
            },
          ),
        ],
      ),
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
