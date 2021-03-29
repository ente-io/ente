import 'dart:ui';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_password_strength/flutter_password_strength.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/key_gen_result.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/web_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:share/share.dart';

class PasswordEntryPage extends StatefulWidget {
  final bool isUpdatePassword;

  PasswordEntryPage({this.isUpdatePassword = false, Key key}) : super(key: key);

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isUpdatePassword
            ? "change password"
            : "encryption password"),
      ),
      body: _getBody(),
      resizeToAvoidBottomInset: false,
    );
  }

  Widget _getBody() {
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
                // Image.asset(
                //   "assets/vault.png",
                //   width: 196,
                //   height: 196,
                // ),
                Padding(padding: EdgeInsets.all(12)),
                Text(
                  "enter a" +
                      (widget.isUpdatePassword ? " new " : " ") +
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
                    widget.isUpdatePassword
                        ? "change password"
                        : "set password",
                    fontSize: 18,
                    onPressed: _passwordController1.text.isNotEmpty &&
                            _passwordController2.text.isNotEmpty
                        ? () {
                            if (_passwordController1.text !=
                                _passwordController2.text) {
                              showErrorDialog(context, "uhm...",
                                  "the passwords you entered don't match");
                            } else if (_passwordStrength <
                                kPasswordStrengthThreshold) {
                              showErrorDialog(context, "weak password",
                                  "the password you have chosen is too simple, please choose another one");
                            } else {
                              _showRecoveryCodeDialog();
                            }
                          }
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

  Future<void> _showRecoveryCodeDialog() async {
    final dialog = createProgressDialog(context, "generating keys...");
    await dialog.show();
    try {
      final result =
          await Configuration.instance.generateKey(_passwordController1.text);
      await dialog.hide();
      _showPasswordConfirmationDialog(result);
    } catch (e) {
      await dialog.hide();
      showGenericErrorDialog(context);
    }
  }

  void _showPasswordConfirmationDialog(final KeyGenResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RecoveryCodeDialog(result, widget.isUpdatePassword);
      },
      barrierColor: Colors.black.withOpacity(0.85),
      barrierDismissible: false,
    );
  }
}

class RecoveryCodeDialog extends StatefulWidget {
  final KeyGenResult result;
  final bool isUpdatePassword;

  RecoveryCodeDialog(this.result, this.isUpdatePassword, {Key key})
      : super(key: key);

  @override
  _RecoveryCodeDialogState createState() => _RecoveryCodeDialogState();
}

class _RecoveryCodeDialogState extends State<RecoveryCodeDialog> {
  bool _hasTriedToSave = false;

  @override
  Widget build(BuildContext context) {
    final recoveryKey = widget.result.privateKeyAttributes.recoveryKey;
    List<Widget> actions = [];
    if (!_hasTriedToSave) {
      actions.add(TextButton(
        child: Text(
          "save later",
          style: TextStyle(
            color: Colors.red,
          ),
        ),
        onPressed: () async {
          _saveKeys();
        },
      ));
    }
    actions.add(
      TextButton(
        child: Text(
          "save",
          style: TextStyle(
            color: Theme.of(context).buttonColor,
          ),
        ),
        onPressed: () {
          _shareRecoveryKey(recoveryKey);
        },
      ),
    );
    if (_hasTriedToSave) {
      actions.add(
        TextButton(
          child: Text(
            "continue",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          onPressed: () async {
            _saveKeys();
          },
        ),
      );
    }
    return AlertDialog(
      title: Text("recovery key"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "if you forget your password, you can recover your data with this key"),
            Padding(padding: EdgeInsets.all(8)),
            GestureDetector(
              onTap: () async {
                await Clipboard.setData(new ClipboardData(text: recoveryKey));
                showToast("recovery key copied to clipboard");
                setState(() {
                  _hasTriedToSave = true;
                });
              },
              child: Container(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    recoveryKey,
                    style: TextStyle(
                      fontSize: 16,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(padding: EdgeInsets.all(8)),
            Text(
              "please save this key in a safe place",
              style: TextStyle(height: 1.2),
            ),
          ],
        ),
      ),
      actions: actions,
    );
  }

  Future _shareRecoveryKey(String recoveryKey) async {
    final recoveryKeyFile = io.File(
        Configuration.instance.getTempDirectory() + "ente-recovery-key.txt");
    if (recoveryKeyFile.existsSync()) {
      recoveryKeyFile.deleteSync();
    }
    recoveryKeyFile.writeAsStringSync(recoveryKey);
    await Share.shareFiles([recoveryKeyFile.path]);
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _hasTriedToSave = true;
        });
      }
    });
  }

  void _saveKeys() {
    Navigator.of(context, rootNavigator: true).pop();
    if (widget.isUpdatePassword) {
      UserService.instance.updateKeyAttributes(context, widget.result);
    } else {
      UserService.instance.setupAttributes(context, widget.result);
    }
  }
}
