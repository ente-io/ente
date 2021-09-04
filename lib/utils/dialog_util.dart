import 'dart:math';

import 'package:confetti/confetti.dart';
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
    backgroundColor: Color.fromRGBO(10, 15, 15, 1.0),
    progressWidget: loadWidget,
    borderRadius: 4.0,
    elevation: 10.0,
    insetAnimCurve: Curves.easeInOut,
  );
  return dialog;
}

Future<dynamic> showErrorDialog(BuildContext context, String title, String content) {
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(content),
    actions: [
      TextButton(
        child: Text("ok"),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop('dialog');
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

Future<dynamic> showGenericErrorDialog(BuildContext context) {
  return showErrorDialog(context, "something went wrong", "please try again.");
}

Future<T> showConfettiDialog<T>({
  @required BuildContext context,
  WidgetBuilder builder,
  bool barrierDismissible = true,
  Color barrierColor,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings routeSettings,
  Alignment confettiAlignment = Alignment.center,
}) {
  final pageBuilder = Builder(
    builder: builder,
  );
  ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 1));
  _confettiController.play();
  return showDialog(
    context: context,
    builder: (BuildContext buildContext) {
      return Stack(
        children: [
          pageBuilder,
          Align(
            alignment: confettiAlignment,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0,
              numberOfParticles: 100, // a lot of particles at once
              gravity: 1,
              blastDirectionality: BlastDirectionality.explosive,
            ),
          ),
        ],
      );
    },
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
  );
}
