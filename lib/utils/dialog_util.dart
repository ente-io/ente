import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:progress_dialog/progress_dialog.dart';

ProgressDialog createProgressDialog(BuildContext context, String message) {
  final dialog = ProgressDialog(
    context,
    type: ProgressDialogType.Normal,
    isDismissible: false,
  );
  dialog.style(
    message: message,
    messageTextStyle: TextStyle(color: Colors.white),
    backgroundColor: Colors.grey[850],
    progressWidget: loadWidget,
    borderRadius: 4.0,
    elevation: 10.0,
    insetAnimCurve: Curves.easeInOut,
  );
  return dialog;
}

void showErrorDialog(BuildContext context, String title, String content) {
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(content),
    actions: [
      FlatButton(
        child: Text("OK"),
        onPressed: () {
          Navigator.of(context).pop();
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

void showGenericErrorDialog(BuildContext context) {
  showErrorDialog(
      context, "Oops.", "Sorry, something went wrong. Please try again.");
}
