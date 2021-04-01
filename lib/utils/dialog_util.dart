import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/progress_dialog.dart';

ProgressDialog createProgressDialog(BuildContext context, String message) {
  final dialog = ProgressDialog(
    context,
    type: ProgressDialogType.Normal,
    isDismissible: false,
    barrierColor: Colors.black.withOpacity(0.85),
  );
  dialog.style(
    message: message,
    messageTextStyle: TextStyle(color: Colors.white),
    backgroundColor: Color.fromRGBO(20, 20, 20, 1.0),
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
        child: Text("ok"),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop('dialog');
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
  showErrorDialog(context, "something went wrong", "please try again.");
}
