import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/utils/dialog_util.dart';

class PassphraseEntryPage extends StatefulWidget {
  PassphraseEntryPage({Key key}) : super(key: key);

  @override
  _PassphraseEntryPageState createState() => _PassphraseEntryPageState();
}

class _PassphraseEntryPageState extends State<PassphraseEntryPage> {
  final _passphraseController1 = TextEditingController(),
      _passphraseController2 = TextEditingController();

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
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 40, 16, 16),
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
                controller: _passphraseController1,
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
                controller: _passphraseController2,
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
                  onPressed: _passphraseController1.text.isNotEmpty &&
                          _passphraseController2.text.isNotEmpty
                      ? () {
                          if (_passphraseController1.text !=
                              _passphraseController2.text) {
                            showErrorDialog(context, "Uhm...",
                                "The passphrases you entered don't match.");
                          } else {
                            _showPassphraseConfirmationDialog();
                          }
                        }
                      : null,
                )),
          ],
        ),
      ),
    );
  }

  void _showPassphraseConfirmationDialog() {
    AlertDialog alert = AlertDialog(
      title: Text("Confirmation"),
      content: SingleChildScrollView(
        child: Column(children: [
          Text("The passphrase you are promising to never forget is"),
          Padding(padding: EdgeInsets.all(8)),
          Text(_passphraseController1.text,
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
                .setupAttributes(context, _passphraseController1.text);
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
