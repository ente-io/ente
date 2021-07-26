import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_password_strength/flutter_password_strength.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/billing_plan.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/web_page.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';

class EmailEntryPage extends StatefulWidget {
  EmailEntryPage({Key key}) : super(key: key);

  @override
  _EmailEntryPageState createState() => _EmailEntryPageState();
}

class _EmailEntryPageState extends State<EmailEntryPage> {
  static const kPasswordStrengthThreshold = 0.4;

  final _config = Configuration.instance;
  final _passwordController1 = TextEditingController(),
      _passwordController2 = TextEditingController();

  String _email;
  double _passwordStrength = 0;
  bool _hasAgreedToTOS = true;
  bool _hasAgreedToE2E = false;
  bool _password1Visible = false;
  bool _password2Visible = false;
  final _password1FocusNode = FocusNode();
  final _password2FocusNode = FocusNode();
  bool _password1InFocus = false;
  bool _password2InFocus = false;

  @override
  void initState() {
    _email = _config.getEmail();
    _password1FocusNode.addListener(() {
      setState(() {
        _password1InFocus = _password1FocusNode.hasFocus;
      });
    });
    _password2FocusNode.addListener(() {
      setState(() {
        _password2InFocus = _password2FocusNode.hasFocus;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: Hero(
        tag: "sign_up",
        child: Material(
          type: MaterialType.transparency,
          child: Text(
            "sign up",
            style: TextStyle(
              fontSize: 18,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: appBar,
      body: _getBody(),
      // resizeToAvoidBottomInset: false,
    );
  }

  Widget _getBody() {
    return Column(
      children: [
        FlutterPasswordStrength(
          password: _passwordController1.text,
          backgroundColor: Colors.white.withOpacity(0.1),
          strengthCallback: (strength) {
            _passwordStrength = strength;
          },
          strengthColors: passwordStrengthColors,
        ),
        Expanded(
          child: ListView(
            children: [
              Padding(padding: EdgeInsets.all(40)),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
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
                      _email = value.trim();
                    });
                  },
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  initialValue: _email,
                  textInputAction: TextInputAction.next,
                ),
              ),
              Padding(padding: EdgeInsets.all(8)),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  controller: _passwordController1,
                  obscureText: !_password1Visible,
                  decoration: InputDecoration(
                    hintText: "password",
                    hintStyle: TextStyle(
                      color: Colors.white30,
                    ),
                    contentPadding: EdgeInsets.all(12),
                    suffixIcon: _password1InFocus
                        ? IconButton(
                            icon: Icon(
                              _password1Visible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white.withOpacity(0.5),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _password1Visible = !_password1Visible;
                              });
                            },
                          )
                        : null,
                  ),
                  focusNode: _password1FocusNode,
                  onChanged: (_) {
                    setState(() {});
                  },
                  onEditingComplete: () {
                    _password1FocusNode.unfocus();
                    _password2FocusNode.requestFocus();
                  },
                ),
              ),
              Padding(padding: EdgeInsets.all(8)),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  controller: _passwordController2,
                  obscureText: !_password2Visible,
                  decoration: InputDecoration(
                    hintText: "confirm password",
                    hintStyle: TextStyle(
                      color: Colors.white30,
                    ),
                    contentPadding: EdgeInsets.all(12),
                    suffixIcon: _password2InFocus
                        ? IconButton(
                            icon: Icon(
                              _password2Visible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white.withOpacity(0.5),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _password2Visible = !_password2Visible;
                              });
                            },
                          )
                        : null,
                  ),
                  focusNode: _password2FocusNode,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
              ),
              _getAgreement(),
              Padding(padding: EdgeInsets.all(20)),
              Container(
                width: double.infinity,
                height: 64,
                padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
                child: button(
                  "sign up",
                  onPressed: _isFormValid()
                      ? () {
                          if (!isValidEmail(_email)) {
                            showErrorDialog(context, "invalid email",
                                "please enter a valid email address.");
                          } else if (_passwordController1.text !=
                              _passwordController2.text) {
                            showErrorDialog(context, "uhm...",
                                "the passwords you entered don't match");
                          } else if (_passwordStrength <
                              kPasswordStrengthThreshold) {
                            showErrorDialog(context, "weak password",
                                "the password you have chosen is too simple, please choose another one");
                          } else {
                            _config
                                .setVolatilePassword(_passwordController1.text);
                            _config.setEmail(_email);
                            UserService.instance.getOtt(context, _email);
                          }
                        }
                      : null,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Container _getAgreement() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        children: [
          _getTOSAgreement(),
          _getPasswordAgreement(),
        ],
      ),
    );
  }

  Widget _getTOSAgreement() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _hasAgreedToTOS = !_hasAgreedToTOS;
        });
      },
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          Checkbox(
              value: _hasAgreedToTOS,
              onChanged: (value) {
                setState(() {
                  _hasAgreedToTOS = value;
                });
              }),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "I agree to the ",
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
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPasswordAgreement() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _hasAgreedToE2E = !_hasAgreedToE2E;
        });
      },
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          Checkbox(
              value: _hasAgreedToE2E,
              onChanged: (value) {
                setState(() {
                  _hasAgreedToE2E = value;
                });
              }),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text:
                        "I understand that if I lose my password, I may lose my data since my data is ",
                  ),
                  TextSpan(
                    text: "end-to-end encrypted",
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
                                  "encryption", "https://ente.io/encryption");
                            },
                          ),
                        );
                      },
                  ),
                  TextSpan(text: " with ente"),
                ],
                style: TextStyle(
                  height: 1.5,
                  fontSize: 12,
                  fontFamily: 'Ubuntu',
                  color: Colors.white70,
                ),
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  bool _isFormValid() {
    return _email != null &&
        _email.isNotEmpty &&
        _passwordController1.text.isNotEmpty &&
        _passwordController2.text.isNotEmpty &&
        _hasAgreedToTOS &&
        _hasAgreedToE2E;
  }
}

class PricingWidget extends StatelessWidget {
  const PricingWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BillingPlans>(
      future: BillingService.instance.getBillingPlans(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return _buildPlans(context, snapshot.data);
        } else if (snapshot.hasError) {
          return Text("Oops, something went wrong.");
        }
        return loadWidget;
      },
    );
  }

  Container _buildPlans(BuildContext context, BillingPlans plans) {
    final planWidgets = <BillingPlanWidget>[];
    for (final plan in plans.plans) {
      final productID = Platform.isAndroid ? plan.androidID : plan.iosID;
      if (productID != null && productID.isNotEmpty) {
        planWidgets.add(BillingPlanWidget(plan));
      }
    }
    final freePlan = plans.freePlan;
    return Container(
      height: 280,
      color: Theme.of(context).cardColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text(
            "pricing",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: planWidgets,
            ),
          ),
          Text("we offer a free trial of " +
              convertBytesToReadableFormat(freePlan.storage) +
              " for " +
              freePlan.duration.toString() +
              " " +
              freePlan.period),
          GestureDetector(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white38,
                ),
                Padding(padding: EdgeInsets.all(1)),
                Text(
                  "close",
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
    );
  }
}

class BillingPlanWidget extends StatelessWidget {
  final BillingPlan plan;

  const BillingPlanWidget(
    this.plan, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: Colors.black.withOpacity(0.2),
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 20, 12, 20),
          child: Column(
            children: [
              Text(
                convertBytesToGBs(plan.storage, precision: 0).toString() +
                    " GB",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(4),
              ),
              Text(
                plan.price + " / " + plan.period,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
