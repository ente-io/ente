import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/user_authenticated_event.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/utils/dialog_util.dart';

class PassphraseReentryPage extends StatefulWidget {
  PassphraseReentryPage({Key key}) : super(key: key);

  @override
  _PassphraseReentryPageState createState() => _PassphraseReentryPageState();
}

class _PassphraseReentryPageState extends State<PassphraseReentryPage> {
  final _passphraseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.lock),
        title: Text(
          "Encryption Passphrase",
        ),
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
            Image.asset(
              "assets/vault.png",
              width: 196,
              height: 196,
            ),
            Padding(padding: EdgeInsets.all(20)),
            Text(
              "Please enter your passphrase.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            Padding(padding: EdgeInsets.all(12)),
            TextFormField(
              decoration: InputDecoration(
                hintText: "that thing you promised to never forget",
                contentPadding: EdgeInsets.all(20),
              ),
              style: TextStyle(
                fontSize: 14,
              ),
              controller: _passphraseController,
              autofocus: false,
              autocorrect: false,
              keyboardType: TextInputType.visiblePassword,
              onChanged: (_) {
                setState(() {});
              },
            ),
            Padding(padding: EdgeInsets.all(12)),
            Container(
                padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
                width: double.infinity,
                height: 64,
                child: button(
                  "Verify Passphrase",
                  onPressed: _passphraseController.text.isNotEmpty
                      ? () async {
                          final dialog =
                              createProgressDialog(context, "Please wait...");
                          await dialog.show();
                          try {
                            await Configuration.instance.decryptAndSaveKey(
                                _passphraseController.text,
                                Configuration.instance.getKeyAttributes());
                          } catch (e) {
                            await dialog.hide();
                            showErrorDialog(context, "Incorrect passphrase",
                                "Please try again.");
                            return;
                          }
                          await dialog.hide();
                          Bus.instance.fire(UserAuthenticatedEvent());
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                      : null,
                )),
          ],
        ),
      ),
    );
  }
}
