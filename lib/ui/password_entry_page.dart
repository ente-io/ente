import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_password_strength/flutter_password_strength.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/subscription_purchased_event.dart';
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

  final _logger = Logger("PasswordEntry");
  final _passwordController1 = TextEditingController(),
      _passwordController2 = TextEditingController();
  double _passwordStrength = 0;
  String _password;
  bool _password1Visible = false;
  bool _password2Visible = false;
  final _password1FocusNode = FocusNode();
  final _password2FocusNode = FocusNode();
  bool _password1InFocus = false;
  bool _password2InFocus = false;

  @override
  void initState() {
    super.initState();
    _password = Configuration.instance.getVolatilePassword();
    if (_password != null) {
      Future.delayed(Duration.zero, () => _showRecoveryCodeDialog(_password));
    }
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
  }

  @override
  Widget build(BuildContext context) {
    String title = "set password";
    if (widget.mode == PasswordEntryMode.update) {
      title = "change password";
    } else if (widget.mode == PasswordEntryMode.reset) {
      title = "reset password";
    } else if (_password != null) {
      title = "encryption keys";
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading:
            widget.mode == PasswordEntryMode.reset ? Icon(Icons.lock) : null,
      ),
      body: _getBody(title),
      resizeToAvoidBottomInset: false,
    );
  }

  Widget _getBody(String buttonText) {
    if (_password != null) {
      return Container();
    }
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
                    obscureText: !_password1Visible,
                    controller: _passwordController1,
                    autofocus: false,
                    autocorrect: false,
                    keyboardType: TextInputType.visiblePassword,
                    onChanged: (_) {
                      setState(() {});
                    },
                    textInputAction: TextInputAction.next,
                    focusNode: _password1FocusNode,
                  ),
                ),
                Padding(padding: EdgeInsets.all(8)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: "password again",
                      contentPadding: EdgeInsets.all(20),
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
                    obscureText: !_password2Visible,
                    controller: _passwordController2,
                    autofocus: false,
                    autocorrect: false,
                    keyboardType: TextInputType.visiblePassword,
                    onChanged: (_) {
                      setState(() {});
                    },
                    focusNode: _password2FocusNode,
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
        _showRecoveryCodeDialog(_passwordController1.text);
      } else {
        _updatePassword();
      }
    }
  }

  void _updatePassword() async {
    final dialog =
        createProgressDialog(context, "generating encryption keys...");
    await dialog.show();
    try {
      final keyAttributes = await Configuration.instance
          .updatePassword(_passwordController1.text);
      await UserService.instance.updateKeyAttributes(keyAttributes);
      await dialog.hide();
      showToast("password changed successfully");
      Navigator.of(context).pop();
      if (widget.mode == PasswordEntryMode.reset) {
        Bus.instance.fire(SubscriptionPurchasedEvent());
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e, s) {
      _logger.severe(e, s);
      await dialog.hide();
      showGenericErrorDialog(context);
    }
  }

  Future<void> _showRecoveryCodeDialog(String password) async {
    final dialog =
        createProgressDialog(context, "generating encryption keys...");
    await dialog.show();
    try {
      final result = await Configuration.instance.generateKey(password);
      Configuration.instance.setVolatilePassword(null);
      await dialog.hide();
      onDone() async {
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
          _logger.severe(e, s);
          await dialog.hide();
          showGenericErrorDialog(context);
        }
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return RecoveryKeyDialog(
            result.privateKeyAttributes.recoveryKey,
            "continue",
            onDone,
            isDismissible: false,
          );
        },
        barrierColor: Colors.black.withOpacity(0.85),
        barrierDismissible: false,
      );
    } catch (e) {
      _logger.severe(e);
      await dialog.hide();
      if (e is UnsupportedError) {
        showErrorDialog(context, "insecure device",
            "sorry, we could not generate secure keys on this device.\n\nplease sign up from a different device.");
      } else {
        showGenericErrorDialog(context);
      }
    }
  }
}
