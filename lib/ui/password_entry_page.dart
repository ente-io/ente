import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_password_strength/flutter_password_strength.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/recovery_key_dialog.dart';
import 'package:photos/ui/subscription_page.dart';
import 'package:photos/ui/web_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

enum PasswordEntryMode {
  set,
  update,
  reset,
}

class PasswordEntryPage extends StatefulWidget {
  final PasswordEntryMode mode;

  PasswordEntryPage({this.mode = PasswordEntryMode.set, Key key})
      : super(key: key);

  @override
  _PasswordEntryPageState createState() => _PasswordEntryPageState();
}

class _PasswordEntryPageState extends State<PasswordEntryPage> {
  static const kPasswordStrengthThreshold = 0.4;

  final _passwordController1 = TextEditingController(),
      _passwordController2 = TextEditingController();
  double _passwordStrength = 0;

  @override
  Widget build(BuildContext context) {
    String title = "set password";
    if (widget.mode == PasswordEntryMode.update) {
      title = "change password";
    } else if (widget.mode == PasswordEntryMode.reset) {
      title = "reset password";
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _getBody(title),
      resizeToAvoidBottomInset: false,
    );
  }

  Widget _getBody(String buttonText) {
    return Column(
      children: [
        FlutterPasswordStrength(
          password: _passwordController1.text,
          backgroundColor: Colors.grey[850],
          strengthCallback: (strength) {
            _passwordStrength = strength;
          },
        ),
        SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 36, 16, 16),
            child: Column(
              children: [
                Padding(padding: EdgeInsets.all(12)),
                Text(
                  "enter a" +
                      (widget.mode != PasswordEntryMode.set ? " new " : " ") +
                      "password we can use to encrypt your data",
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
                Padding(padding: EdgeInsets.all(20)),
                Container(
                  width: double.infinity,
                  height: 64,
                  padding: EdgeInsets.fromLTRB(40, 0, 40, 0),
                  child: button(
                    buttonText,
                    fontSize: 18,
                    onPressed: _passwordController1.text.isNotEmpty &&
                            _passwordController2.text.isNotEmpty
                        ? _onButtonPress
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: Container()),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return WebPage("how it works", "https://ente.io/encryption");
                },
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(40),
            child: RichText(
              text: TextSpan(
                text: "how it works",
                style: TextStyle(
                  color: Colors.blue,
                  fontFamily: 'Ubuntu',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onButtonPress() {
    if (_passwordController1.text != _passwordController2.text) {
      showErrorDialog(
          context, "uhm...", "the passwords you entered don't match");
    } else if (_passwordStrength < kPasswordStrengthThreshold) {
      showErrorDialog(context, "weak password",
          "the password you have chosen is too simple, please choose another one");
    } else {
      if (widget.mode == PasswordEntryMode.set) {
        _showRecoveryCodeDialog();
      } else {
        _updatePassword();
      }
    }
  }

  void _updatePassword() async {
    final dialog = createProgressDialog(context, "please wait...");
    await dialog.show();
    try {
      final keyAttributes = await Configuration.instance
          .updatePassword(_passwordController1.text);
      await UserService.instance.updateKeyAttributes(keyAttributes);
      await dialog.hide();
      showToast("password changed successfully");
      Navigator.of(context).pop();
      if (widget.mode == PasswordEntryMode.reset) {
        if (!BillingService.instance.hasActiveSubscription()) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (BuildContext context) {
                return SubscriptionPage(isOnboarding: true);
              },
            ),
          );
        } else {
          Bus.instance.fire(SubscriptionPurchasedEvent());
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      await dialog.hide();
      showGenericErrorDialog(context);
    }
  }

  Future<void> _showRecoveryCodeDialog() async {
    final dialog =
        createProgressDialog(context, "generating encryption keys...");
    await dialog.show();
    try {
      final result =
          await Configuration.instance.generateKey(_passwordController1.text);
      await dialog.hide();
      final onDone = () async {
        final dialog = createProgressDialog(context, "please wait...");
        await dialog.show();
        try {
          await UserService.instance.setAttributes(result);
          await dialog.hide();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (BuildContext context) {
                return SubscriptionPage(isOnboarding: true);
              },
            ),
            (route) => route.isFirst,
          );
        } catch (e, s) {
          Logger("PEP").severe(e, s);
          await dialog.hide();
          showGenericErrorDialog(context);
        }
      };
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return RecoveryKeyDialog(
              result.privateKeyAttributes.recoveryKey, "continue", onDone);
        },
        barrierColor: Colors.black.withOpacity(0.85),
        barrierDismissible: false,
      );
    } catch (e) {
      await dialog.hide();
      showGenericErrorDialog(context);
    }
  }
}
