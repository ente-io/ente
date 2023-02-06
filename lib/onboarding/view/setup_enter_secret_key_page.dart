import "package:ente_auth/l10n/l10n.dart";
import 'package:ente_auth/models/code.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/totp_util.dart';
import "package:flutter/material.dart";

class SetupEnterSecretKeyPage extends StatefulWidget {
  final Code? code;

  SetupEnterSecretKeyPage({this.code, Key? key}) : super(key: key);

  @override
  State<SetupEnterSecretKeyPage> createState() =>
      _SetupEnterSecretKeyPageState();
}

class _SetupEnterSecretKeyPageState extends State<SetupEnterSecretKeyPage> {
  late TextEditingController _issuerController;
  late TextEditingController _accountController;
  late TextEditingController _secretController;

  @override
  void initState() {
    _issuerController = TextEditingController(
      text: widget.code != null
          ? Uri.decodeFull(widget.code!.issuer).trim()
          : null,
    );
    _accountController = TextEditingController(
      text: widget.code != null
          ? Uri.decodeFull(widget.code!.account).trim()
          : null,
    );
    _secretController = TextEditingController(
      text: widget.code != null ? widget.code!.secret : null,
    );
    super.initState();
  }

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
                    hintText: l10n.codeIssuerHint,
                  ),
                  controller: _issuerController,
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
                    hintText: l10n.codeSecretKeyHint,
                  ),
                  controller: _secretController,
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
                    hintText: l10n.codeAccountHint,
                  ),
                  controller: _accountController,
                ),
                const SizedBox(
                  height: 40,
                ),
                SizedBox(
                  width: 400,
                  child: OutlinedButton(
                    onPressed: () {
                      if ((_accountController.text.trim().isEmpty &&
                              _issuerController.text.trim().isEmpty) ||
                          _secretController.text.trim().isEmpty) {
                        String message;
                        if (_secretController.text.trim().isEmpty) {
                          message = "Secret can not be empty";
                        } else {
                          message = "Both account and issuer can not be empty";
                        }
                        _showIncorrectDetailsDialog(context, message: message);
                        return;
                      }
                      try {
                        final code = Code.fromAccountAndSecret(
                          _accountController.text.trim(),
                          _issuerController.text.trim(),
                          _secretController.text.trim().replaceAll(' ', ''),
                        );
                        // Verify the validity of the code
                        getTotp(code);
                        if (widget.code != null) {
                          code.generatedID = widget.code!.generatedID;
                        }
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
                      child: Text(l10n.saveAction),
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

  void _showIncorrectDetailsDialog(
    BuildContext context, {
    String message = "Please verify the entered details",
  }) {
    showErrorDialog(
      context,
      "Incorrect details",
      message,
    );
  }
}
