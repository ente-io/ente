// @dart=2.9

import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/common/progress_dialog.dart';

ProgressDialog createProgressDialog(
  BuildContext context,
  String message, {
  isDismissible = false,
}) {
  final dialog = ProgressDialog(
    context,
    type: ProgressDialogType.normal,
    isDismissible: isDismissible,
    barrierColor: Colors.black12,
  );
  dialog.style(
    message: message,
    messageTextStyle: Theme.of(context).textTheme.caption,
    backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
    progressWidget: const EnteLoadingWidget(),
    borderRadius: 10,
    elevation: 10.0,
    insetAnimCurve: Curves.easeInOut,
  );
  return dialog;
}

Future<dynamic> showErrorDialog(
  BuildContext context,
  String title,
  String content,
) {
  final AlertDialog alert = AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    title: title.isEmpty
        ? const SizedBox.shrink()
        : Text(
            title,
            style: Theme.of(context).textTheme.headline6,
          ),
    content: Text(content),
    actions: [
      TextButton(
        child: Text(
          "Ok",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
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
    barrierColor: Colors.black12,
  );
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
  final ConfettiController confettiController =
      ConfettiController(duration: const Duration(seconds: 1));
  confettiController.play();
  return showDialog(
    context: context,
    builder: (BuildContext buildContext) {
      return Stack(
        children: [
          pageBuilder,
          Align(
            alignment: confettiAlignment,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0,
              numberOfParticles: 100,
              // a lot of particles at once
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
