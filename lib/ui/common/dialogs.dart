import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum DialogUserChoice {
  firstChoice,
  secondChoice
}

// if dialog is dismissed by tapping outside, this will return null
Future<T> showChoiceDialog<T>(
  BuildContext context,
  String title,
  String content, {
  String firstAction = 'ok',
  String secondAction = 'cancel',
}) {
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(content),
    actions: [
      TextButton(
        child: Text(
          firstAction,
          style: TextStyle(
            color: Theme.of(context).buttonColor,
          ),
        ),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop(DialogUserChoice.firstChoice);
        },
      ),
      TextButton(
        child: Text(secondAction),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop(DialogUserChoice.secondChoice);
        },
      ),
    ],
  );

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
    barrierColor: Colors.black87,
  );
}