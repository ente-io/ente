import "package:ente_auth/l10n/l10n.dart";
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/models/button_result.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/totp_util.dart';
import "package:flutter/material.dart";

class SetupEnterSecretKeyPage extends StatefulWidget {
  final Code? code;

  SetupEnterSecretKeyPage({this.code, super.key});

  @override
  State<SetupEnterSecretKeyPage> createState() =>
      _SetupEnterSecretKeyPageState();
}

class _SetupEnterSecretKeyPageState extends State<SetupEnterSecretKeyPage> {
  late TextEditingController _issuerController;
  late TextEditingController _accountController;
  late TextEditingController _secretController;
  late bool _secretKeyObscured;

  @override
  void initState() {
    _issuerController = TextEditingController(
      text: widget.code != null ? safeDecode(widget.code!.issuer).trim() : null,
    );
    _accountController = TextEditingController(
      text:
          widget.code != null ? safeDecode(widget.code!.account).trim() : null,
    );
    _secretController = TextEditingController(
      text: widget.code?.secret,
    );
    _secretKeyObscured = widget.code != null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importAccountPageTitle),
      ),
      body: Center(
        child: SingleChildScrollView(
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
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _secretKeyObscured = !_secretKeyObscured;
                        });
                      },
                      icon: _secretKeyObscured
                          ? const Icon(Icons.visibility_off_rounded)
                          : const Icon(Icons.visibility_rounded),
                    ),
                  ),
                  obscureText: _secretKeyObscured,
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
                    onPressed: () async {
                      if ((_accountController.text.trim().isEmpty &&
                              _issuerController.text.trim().isEmpty) ||
                          _secretController.text.trim().isEmpty) {
                        String message;
                        if (_secretController.text.trim().isEmpty) {
                          message = context.l10n.secretCanNotBeEmpty;
                        } else {
                          message =
                              context.l10n.bothIssuerAndAccountCanNotBeEmpty;
                        }
                        _showIncorrectDetailsDialog(context, message: message);
                        return;
                      }
                      await _saveCode();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4,
                      ),
                      child: Text(l10n.saveAction),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveCode() async {
    try {
      final account = _accountController.text.trim();
      final issuer = _issuerController.text.trim();
      final secret = _secretController.text.trim().replaceAll(' ', '');
      if (widget.code != null && widget.code!.secret != secret) {
        ButtonResult? result = await showChoiceActionSheet(
          context,
          title: context.l10n.warning,
          body: context.l10n.confirmUpdatingkey,
          firstButtonLabel: context.l10n.yes,
          secondButtonAction: ButtonAction.cancel,
          secondButtonLabel: context.l10n.cancel,
        );
        if (result == null) return;
        if (result.action != ButtonAction.first) {
          return;
        }
      }
      final Code newCode = widget.code == null
          ? Code.fromAccountAndSecret(
              account,
              issuer,
              secret,
            )
          : widget.code!.copyWith(
              account: account,
              issuer: issuer,
              secret: secret,
            );
      // Verify the validity of the code
      getOTP(newCode);
      Navigator.of(context).pop(newCode);
    } catch (e) {
      _showIncorrectDetailsDialog(context);
    }
  }

  void _showIncorrectDetailsDialog(
    BuildContext context, {
    String? message,
  }) {
    showErrorDialog(
      context,
      context.l10n.incorrectDetails,
      message ?? context.l10n.pleaseVerifyDetails,
    );
  }
}
