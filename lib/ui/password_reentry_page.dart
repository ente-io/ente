import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/user_authenticated_event.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/utils/dialog_util.dart';

class PasswordReentryPage extends StatefulWidget {
  PasswordReentryPage({Key key}) : super(key: key);

  @override
  _PasswordReentryPageState createState() => _PasswordReentryPageState();
}

class _PasswordReentryPageState extends State<PasswordReentryPage> {
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.lock),
        title: Text(
          "encryption password",
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
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: "enter your password",
                  contentPadding: EdgeInsets.all(20),
                ),
                style: TextStyle(
                  fontSize: 14,
                ),
                controller: _passwordController,
                autofocus: false,
                autocorrect: false,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                onChanged: (_) {
                  setState(() {});
                },
              ),
            ),
            Padding(padding: EdgeInsets.all(12)),
            Container(
                padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
                width: double.infinity,
                height: 64,
                child: button(
                  "sign in",
                  fontSize: 18,
                  onPressed: _passwordController.text.isNotEmpty
                      ? () async {
                          final dialog =
                              createProgressDialog(context, "please wait...");
                          await dialog.show();
                          try {
                            await Configuration.instance.decryptAndSaveKey(
                                _passwordController.text,
                                Configuration.instance.getKeyAttributes());
                          } catch (e) {
                            await dialog.hide();
                            showErrorDialog(context, "incorrect password",
                                "please try again");
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
