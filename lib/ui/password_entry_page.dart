import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/account_configured_event.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/payment/subscription.dart';
import 'package:photos/ui/recovery_key_page.dart';
import 'package:photos/ui/web_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';

import 'common/dynamicFAB.dart';

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
  String _volatilePassword;
  String _password;
  String _passwordInInputBox = '';
  bool _password1Visible = false;
  bool _password2Visible = false;
  final _password1FocusNode = FocusNode();
  final _password2FocusNode = FocusNode();
  bool _password1InFocus = false;
  bool _password2InFocus = false;

  Color _cnfPasswordInputFieldColor = null;
  Color _passwordInputFieldColor = null;
  bool _passwordsMatch = false;
  bool _passwordIsValid = false;

  bool _capitalLetterIsPresent = false;
  bool _lenghtIsValid = false; //variables for checking password strength
  bool _specialCharIsPresent = false;

  @override
  void initState() {
    super.initState();
    _volatilePassword = Configuration.instance.getVolatilePassword();
    if (_volatilePassword != null) {
      Future.delayed(
          Duration.zero, () => _showRecoveryCodeDialog(_volatilePassword));
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
    final isKeypadOpen = MediaQuery.of(context).viewInsets.bottom != 0;

    FloatingActionButtonLocation fabLocation() {
      if (isKeypadOpen) {
        return null;
      } else {
        return FloatingActionButtonLocation.centerFloat;
      }
    }

    String title = "Set password";
    if (widget.mode == PasswordEntryMode.update) {
      title = "Change password";
    } else if (widget.mode == PasswordEntryMode.reset) {
      title = "Reset password";
    } else if (_volatilePassword != null) {
      title = "Encryption keys";
    }
    return Scaffold(
      appBar: AppBar(
        leading: widget.mode == PasswordEntryMode.reset
            ? new Container()
            : IconButton(
                icon: Icon(Icons.arrow_back),
                color: Theme.of(context).iconTheme.color,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
        elevation: 0,
      ),
      body: _getBody(title),
      floatingActionButton: DynamicFAB(
          isKeypadOpen: isKeypadOpen,
          isFormValid: _passwordsMatch,
          buttonText: title,
          onPressedFunction: () {
            if (widget.mode == PasswordEntryMode.set) {
              _showRecoveryCodeDialog(_passwordController1.text);
            } else {
              _updatePassword();
            }
          }),
      floatingActionButtonLocation: fabLocation(),
    );
  }

  Widget _getBody(String buttonTextAndHeading) {
    print((!_passwordIsValid &&
        (_passwordInInputBox != '') &&
        _password1InFocus));
    if (_volatilePassword != null) {
      return Container();
    }
    return Column(
      children: [
        Expanded(
          child: AutofillGroup(
            child: ListView(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  child: Text(buttonTextAndHeading,
                      style: Theme.of(context).textTheme.headline4),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Enter a" +
                        (widget.mode != PasswordEntryMode.set ? " new " : " ") +
                        "password we can use to encrypt your data",
                    textAlign: TextAlign.start,
                    style: Theme.of(context)
                        .textTheme
                        .subtitle1
                        .copyWith(fontSize: 14),
                  ),
                ),
                Padding(padding: EdgeInsets.all(8)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RichText(
                      text: TextSpan(
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1
                              .copyWith(fontSize: 14),
                          children: [
                        TextSpan(
                            text:
                                "We don't store this password, so if you forget, "),
                        TextSpan(
                          text: "we cannot decrypt your data",
                          style: Theme.of(context).textTheme.subtitle1.copyWith(
                              fontSize: 14,
                              decoration: TextDecoration.underline),
                        ),
                      ])),
                ),
                // Text("we don't store this password, so if you forget, "),
                // Text.rich(
                //   TextSpan(
                //       text: "we cannot decrypt your data",
                //       style: TextStyle(
                //         decoration: TextDecoration.underline,
                //         fontWeight: FontWeight.bold,
                //       )),
                //   style: TextStyle(
                //     height: 1.3,
                //   ),
                //   textAlign: TextAlign.start,
                // ),
                Padding(padding: EdgeInsets.all(12)),
                // hidden textForm for suggesting auto-fill service for saving
                // password
                // SizedBox(
                //   width: 0,
                //   height: 0,
                //   child: TextFormField(
                //     autofillHints: [
                //       AutofillHints.email,
                //     ],
                //     autocorrect: false,
                //     keyboardType: TextInputType.emailAddress,
                //     initialValue: email,
                //     textInputAction: TextInputAction.next,
                //   ),
                // ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: TextFormField(
                    autofillHints: [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      fillColor: _passwordInputFieldColor,
                      filled: true,
                      hintText: "password",
                      contentPadding: EdgeInsets.all(20),
                      border: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(6)),
                      suffixIcon: _password1InFocus
                          ? IconButton(
                              icon: Icon(
                                _password1Visible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Theme.of(context).iconTheme.color,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _password1Visible = !_password1Visible;
                                });
                              },
                            )
                          : _passwordIsValid
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context)
                                      .inputDecorationTheme
                                      .focusedBorder
                                      .borderSide
                                      .color,
                                )
                              : null,
                    ),
                    obscureText: !_password1Visible,
                    controller: _passwordController1,
                    autofocus: false,
                    autocorrect: false,
                    keyboardType: TextInputType.visiblePassword,
                    onChanged: (password) {
                      setState(() {
                        _passwordInInputBox = password;
                        validatePassword(password);
                        if (_passwordIsValid) {
                          _passwordInputFieldColor =
                              Color.fromRGBO(45, 194, 98, 0.2);
                        } else {
                          _passwordInputFieldColor = null;
                        }
                      });
                    },
                    textInputAction: TextInputAction.next,
                    focusNode: _password1FocusNode,
                  ),
                ),
                Padding(padding: EdgeInsets.all(4)),
                Stack(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: TextFormField(
                        keyboardType: TextInputType.visiblePassword,
                        controller: _passwordController2,
                        obscureText: !_password2Visible,
                        autofillHints: [AutofillHints.newPassword],
                        onEditingComplete: () =>
                            TextInput.finishAutofillContext(),
                        decoration: InputDecoration(
                          fillColor: _cnfPasswordInputFieldColor,
                          filled: true,
                          hintText: "confirm password",
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          suffixIcon: _password2InFocus
                              ? IconButton(
                                  icon: Icon(
                                    _password2Visible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Theme.of(context).iconTheme.color,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _password2Visible = !_password2Visible;
                                    });
                                  },
                                )
                              : _passwordsMatch
                                  ? Icon(
                                      Icons.check,
                                      color: Theme.of(context)
                                          .inputDecorationTheme
                                          .focusedBorder
                                          .borderSide
                                          .color,
                                    )
                                  : null,
                          border: UnderlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        focusNode: _password2FocusNode,
                        onChanged: (cnfPassword) {
                          setState(() {
                            if (_password != null || _password != '') {
                              if (_password == cnfPassword) {
                                _cnfPasswordInputFieldColor =
                                    Color.fromRGBO(45, 194, 98, 0.2);
                                _passwordsMatch = true;
                              } else {
                                _cnfPasswordInputFieldColor = null;
                                _passwordsMatch = false;
                              }
                            }
                          });
                        },
                      ),
                    ),
                    Positioned(
                      bottom: -120,
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Divider(
                        thickness: 1,
                      ),
                    ),
                    Visibility(
                      visible: (!_passwordIsValid &&
                          (_passwordInInputBox != '') &&
                          _password1InFocus),
                      child: Positioned(
                          bottom: -37,
                          child: Row(
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          spreadRadius: 0.5,
                                          color: Theme.of(context).hintColor,
                                          offset: Offset(0, -0.325),
                                        ),
                                      ],
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.zero,
                                        topRight: Radius.zero,
                                        bottomLeft: Radius.circular(5),
                                        bottomRight: Radius.circular(5),
                                      ),
                                      color: Theme.of(context)
                                          .dialogTheme
                                          .backgroundColor,
                                    ),
                                    width: double.infinity,
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                4.0, 8, 4.0, 4.0),
                                            child: Row(
                                              children: [
                                                Padding(
                                                    padding: const EdgeInsets
                                                        .fromLTRB(10, 0, 8, 0),
                                                    child: _lenghtIsValid
                                                        ? Icon(
                                                            Icons.check,
                                                            color:
                                                                CupertinoColors
                                                                    .systemGrey2,
                                                          )
                                                        : Icon(
                                                            Icons.check,
                                                            color: Theme.of(
                                                                    context)
                                                                .dialogTheme
                                                                .backgroundColor,
                                                          )),
                                                Text(
                                                    'Must be minimum 9 characters long',
                                                    style: _lenghtIsValid
                                                        ? TextStyle(
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                            color:
                                                                CupertinoColors
                                                                    .systemGrey)
                                                        : TextStyle(
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    241,
                                                                    118,
                                                                    109)))
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      10, 0, 8, 0),
                                              child: Row(
                                                children: [
                                                  Container(
                                                      child:
                                                          _specialCharIsPresent
                                                              ? Icon(
                                                                  Icons.check,
                                                                  color: CupertinoColors
                                                                      .systemGrey2,
                                                                )
                                                              : Icon(
                                                                  Icons.check,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .dialogTheme
                                                                      .backgroundColor,
                                                                )),
                                                  Text(
                                                      '  Must have special characters',
                                                      style: _specialCharIsPresent
                                                          ? TextStyle(
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough,
                                                              color:
                                                                  CupertinoColors
                                                                      .systemGrey)
                                                          : TextStyle(
                                                              color: Color
                                                                  .fromARGB(
                                                                      255,
                                                                      241,
                                                                      118,
                                                                      109)))
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                4, 4, 4, 8),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      10, 0, 8, 0),
                                              child: Row(
                                                children: [
                                                  Container(
                                                      child:
                                                          _capitalLetterIsPresent
                                                              ? Icon(
                                                                  Icons.check,
                                                                  color: CupertinoColors
                                                                      .systemGrey2,
                                                                )
                                                              : Icon(
                                                                  Icons.check,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .dialogTheme
                                                                      .backgroundColor,
                                                                )),
                                                  Text(
                                                      '  Must have a capital letter',
                                                      style: _capitalLetterIsPresent
                                                          ? TextStyle(
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough,
                                                              color:
                                                                  CupertinoColors
                                                                      .systemGrey)
                                                          : TextStyle(
                                                              color: Color
                                                                  .fromARGB(
                                                                      255,
                                                                      241,
                                                                      118,
                                                                      109)))
                                                ],
                                              ),
                                            ),
                                          ),
                                        ]),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 20,
                              ),
                            ],
                          )),
                    ),
                  ],
                  clipBehavior: Clip.none,
                ),

                // Padding(padding: EdgeInsets.all(8)),
                // Padding(
                //   padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                //   child: TextFormField(
                //     autofillHints: [AutofillHints.newPassword],
                //     decoration: InputDecoration(
                //       filled: true,
                //       hintText: "confirm password",
                //       contentPadding: EdgeInsets.all(20),
                //       border: UnderlineInputBorder(
                //           borderSide: BorderSide.none,
                //           borderRadius: BorderRadius.circular(6)),
                //       suffixIcon: _password2InFocus
                //           ? IconButton(
                //               icon: Icon(
                //                 _password2Visible
                //                     ? Icons.visibility
                //                     : Icons.visibility_off,
                //                 color: Theme.of(context).iconTheme.color,
                //                 size: 20,
                //               ),
                //               onPressed: () {
                //                 setState(() {
                //                   _password2Visible = !_password2Visible;
                //                 });
                //               },
                //             )
                //           : null,
                //     ),
                //     obscureText: !_password2Visible,
                //     controller: _passwordController2,
                //     autofocus: false,
                //     autocorrect: false,
                //     keyboardType: TextInputType.visiblePassword,
                //     onChanged: (_) {
                //       setState(() {});
                //     },
                //     focusNode: _password2FocusNode,
                //   ),
                // ),
                // Padding(
                //   padding: const EdgeInsets.symmetric(vertical: 18),
                //   child: Divider(
                //     thickness: 1,
                //   ),
                // ),
                SizedBox(
                  height: 50,
                ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) {
                          return WebPage(
                              "how it works", "https://ente.io/architecture");
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: RichText(
                      text: TextSpan(
                          text: "how it works",
                          style: Theme.of(context).textTheme.subtitle1.copyWith(
                              fontSize: 14,
                              decoration: TextDecoration.underline)),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.all(20)),
                // Container(
                //   width: double.infinity,
                //   height: 64,
                //   padding: EdgeInsets.fromLTRB(40, 0, 40, 0),
                //   child: ElevatedButton(
                //     child: Text(buttonTextAndHeading),
                //     onPressed: _passwordController1.text.isNotEmpty &&
                //             _passwordController2.text.isNotEmpty
                //         ? _onButtonPress
                //         : null,
                //   ),
                // ),
              ],
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
          Bus.instance.fire(AccountConfiguredEvent());
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (BuildContext context) {
                return getSubscriptionPage(isOnBoarding: true);
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

      routeToPage(
          context,
          RecoveryKeyPage(
            result.privateKeyAttributes.recoveryKey,
            "Continue",
            showAppBar: false,
            isDismissible: false,
            onDone: onDone,
          ));
    } catch (e) {
      _logger.severe(e);
      await dialog.hide();
      if (e is UnsupportedError) {
        showErrorDialog(context, "insecure device",
            "Sorry, we could not generate secure keys on this device.\n\nplease sign up from a different device.");
      } else {
        showGenericErrorDialog(context);
      }
    }
  }

  void validatePassword(String password) {
    var len = password.length;
    _lenghtIsValid = true;
    _specialCharIsPresent = true;
    _capitalLetterIsPresent = true;
    _passwordIsValid = true;
    if (len < 9) {
      _passwordIsValid = false;
      _lenghtIsValid = false;
    }
    if (!RegExp(r"[!@#$%^&*()_+\-=\[\]{};':\\|,.<>\/?]+").hasMatch(password)) {
      _specialCharIsPresent = false;
      _passwordIsValid = false;
    }
    if (!RegExp(r"(.*[A-Z].*)").hasMatch(password)) {
      _capitalLetterIsPresent = false;
      _passwordIsValid = false;
    }
    if (_passwordIsValid) {
      _password = password;
    } else {
      _password = null;
    }
  }
}
