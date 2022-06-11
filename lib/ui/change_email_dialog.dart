import 'package:flutter/material.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';

class ChangeEmailDialog extends StatefulWidget {
  const ChangeEmailDialog({Key key}) : super(key: key);

  @override
  _ChangeEmailDialogState createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<ChangeEmailDialog> {
  String _email;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Enter your email address"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: TextStyle(
                  color: Colors.white30,
                ),
                contentPadding: EdgeInsets.all(12),
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
            "Cancel",
            style: TextStyle(
              color: Colors.redAccent,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(
            "Verify",
            style: TextStyle(
              color: Colors.green,
            ),
          ),
          onPressed: () {
            if (!isValidEmail(_email)) {
              showErrorDialog(context, "Invalid email address",
                  "Please enter a valid email address.",);
              return;
            }
            UserService.instance.getOtt(context, _email, isChangeEmail: true);
          },
        ),
      ],
    );
  }
}
