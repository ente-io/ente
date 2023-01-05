import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:photos/ente_theme_data.dart';

Future showToast(
  BuildContext context,
  String message, {
  toastLength = Toast.LENGTH_LONG,
  iOSDismissOnTap = true,
}) async {
  if (Platform.isAndroid) {
    await Fluttertoast.cancel();
    return Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Theme.of(context).colorScheme.toastBackgroundColor,
      textColor: Theme.of(context).colorScheme.toastTextColor,
      fontSize: 16.0,
    );
  } else {
    EasyLoading.instance
      ..backgroundColor = Theme.of(context).colorScheme.toastBackgroundColor
      ..indicatorColor = Theme.of(context).colorScheme.toastBackgroundColor
      ..textColor = Theme.of(context).colorScheme.toastTextColor
      ..userInteractions = true
      ..loadingStyle = EasyLoadingStyle.custom;
    return EasyLoading.showToast(
      message,
      duration: Duration(seconds: (toastLength == Toast.LENGTH_LONG ? 5 : 1),
      toastPosition: EasyLoadingToastPosition.bottom,
      dismissOnTap: iOSDismissOnTap,
    );
  }
}

Future<void> showShortToast(context, String message) {
  return showToast(context, message, toastLength: Toast.LENGTH_SHORT);
}
