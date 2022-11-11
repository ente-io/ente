import "package:ente_auth/l10n/l10n.dart";
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/totp_util.dart';
import "package:flutter/material.dart";

class SetupEnterSecretKeyPage extends StatefulWidget {
  SetupEnterSecretKeyPage({Key? key}) : super(key: key);

  @override
  State<SetupEnterSecretKeyPage> createState() =>
      _SetupEnterSecretKeyPageState();
}

class _SetupEnterSecretKeyPageState extends State<SetupEnterSecretKeyPage> {
  final _accountController = TextEditingController();
  final _secretController = TextEditingController(text: "");

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importAccountPageTitle),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 40),
            child: Column(
              children: [
                TextFormField(
                  // The validator receives the text that the user has entered.
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter some text";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: l10n.accountNameHint,
                  ),
                  controller: _accountController,
                  autofocus: true,
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  // The validator receives the text that the user has entered.
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter some text";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: l10n.accountKeyHint,
                  ),
                  controller: _secretController,
                ),
                const SizedBox(
                  height: 40,
                ),
                SizedBox(
                  width: 400,
                  child: OutlinedButton(
                    onPressed: () {
                      if (_accountController.text.trim().isEmpty ||
                          _secretController.text.trim().isEmpty) {
                        _showIncorrectDetailsDialog(context);
                        return;
                      }
                      try {
                        final code = Code.fromAccountAndSecret(
                          _accountController.text.trim(),
                          _secretController.text.trim(),
                        );
                        // Verify the validity of the code
                        getTotp(code);
                        Navigator.of(context).pop(code);
                      } catch (e) {
                        _showIncorrectDetailsDialog(context);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4,
                      ),
                      child: Text(l10n.importAddAction),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIncorrectDetailsDialog(BuildContext context) {
    showErrorDialog(
      context,
      "Incorrect details",
      "Please verify the entered details",
    );
  }
}
