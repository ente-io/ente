import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common/dynamicFAB.dart';
import 'package:photos/ui/web_page.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _config = Configuration.instance;
  bool _emailIsValid = false;
  String _email;
  Color _emailInputFieldColor = null;

  @override
  void initState() {
    _email = _config.getEmail();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isKeypadOpen = MediaQuery.of(context).viewInsets.bottom != 0;

    FloatingActionButtonLocation fabLocation() {
      if (isKeypadOpen) {
        return null;
      } else {
        return FloatingActionButtonLocation.centerFloat;
      }
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Theme.of(context).iconTheme.color,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _getBody(),
      floatingActionButton: DynamicFAB(
        isKeypadOpen: isKeypadOpen,
        isFormValid: _emailIsValid,
        buttonText: 'Log in',
        onPressedFunction: () {
          _config.setEmail(_email);
          UserService.instance
              .getOtt(context, _email, isCreateAccountScreen: false);
        },
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
    );
  }

  Widget _getBody() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                child: Text('Welcome back!',
                    style: Theme.of(context).textTheme.headline4),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: TextFormField(
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    fillColor: _emailInputFieldColor,
                    filled: true,
                    hintText: 'Email',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    border: UnderlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(6)),
                    suffixIcon: _emailIsValid
                        ? Icon(
                            Icons.check,
                            size: 20,
                            color: Theme.of(context)
                                .inputDecorationTheme
                                .focusedBorder
                                .borderSide
                                .color,
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _email = value.trim();
                      _emailIsValid = EmailValidator.validate(_email);
                      if (_emailIsValid) {
                        _emailInputFieldColor =
                            Color.fromRGBO(45, 194, 98, 0.2);
                      } else {
                        _emailInputFieldColor = null;
                      }
                    });
                  },
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  //initialValue: _email,
                  autofocus: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Divider(
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1
                              .copyWith(fontSize: 12),
                          children: [
                            TextSpan(
                                text: "By clicking log in, I agree to the "),
                            TextSpan(
                              text: "terms of service",
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) {
                                        return WebPage(
                                            "terms", "https://ente.io/terms");
                                      },
                                    ),
                                  );
                                },
                            ),
                            TextSpan(text: " and "),
                            TextSpan(
                              text: "privacy policy",
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) {
                                        return WebPage("privacy",
                                            "https://ente.io/privacy");
                                      },
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(padding: EdgeInsets.all(8)),
        // Container(
        //   width: double.infinity,
        //   height: 64,
        //   padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
        //   child: ElevatedButton(
        //     child: Text("log in"),
        //     onPressed: _email != null && _email.isNotEmpty
        //         ? () {
        //             if (!isValidEmail(_email)) {
        //               showErrorDialog(context, "invalid email address",
        //                   "please enter a valid email address.");
        //               return;
        //             }
        //             _config.setEmail(_email);
        //             UserService.instance.getOtt(context, _email);
        //           }
        //         : null,
        //   ),
        // ),
      ],
    );
  }
}
