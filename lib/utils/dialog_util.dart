import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/common/progress_dialog.dart';
import 'package:photos/ui/components/button_widget.dart';
import 'package:photos/ui/components/dialog_widget.dart';

typedef DialogBuilder = DialogWidget Function(BuildContext context);

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

Future<ButtonAction?> showConfettiDialog<T>({
  required BuildContext context,
  required DialogBuilder dialogBuilder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Alignment confettiAlignment = Alignment.center,
}) {
  final widthOfScreen = MediaQuery.of(context).size.width;
  final isMobileSmall = widthOfScreen <= mobileSmallThreshold;
  final pageBuilder = Builder(
    builder: dialogBuilder,
  );
  final ConfettiController confettiController =
      ConfettiController(duration: const Duration(seconds: 1));
  confettiController.play();
  return showDialog(
    context: context,
    builder: (BuildContext buildContext) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobileSmall ? 8 : 0),
        child: Stack(
          children: [
            Align(alignment: Alignment.center, child: pageBuilder),
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
        ),
      );
    },
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
  );
}
