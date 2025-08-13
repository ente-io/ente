import 'package:ente_accounts/ente_accounts.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:ente_utils/email_util.dart';
import 'package:flutter/material.dart';

class ChangeEmailDialog extends StatefulWidget {
  const ChangeEmailDialog({super.key});

  @override
  State<ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<ChangeEmailDialog> {
  String _email = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.strings.enterNewEmailHint),
      content: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: InputDecoration(
                hintText: context.strings.email,
                hintStyle: const TextStyle(
                  color: Colors.white30,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (value) {
                setState(() {
                  _email = value;
                });
              },
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              initialValue: _email,
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            context.strings.cancel,
            style: const TextStyle(
              color: Colors.redAccent,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(
            context.strings.verify,
            style: const TextStyle(
              color: Colors.purple,
            ),
          ),
          onPressed: () {
            if (!isValidEmail(_email)) {
              showErrorDialog(
                context,
                context.strings.invalidEmailTitle,
                context.strings.invalidEmailMessage,
              );
              return;
            }
            UserService.instance.sendOtt(context, _email, isChangeEmail: true);
          },
        ),
      ],
    );
  }
}
