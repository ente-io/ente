import 'package:ente_auth/ente_theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast(
  BuildContext context,
  String message, {
  toastLength = Toast.LENGTH_LONG,
  iOSDismissOnTap = true,
}) async {
  try {
    await Fluttertoast.cancel();
    await Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Theme.of(context).colorScheme.toastBackgroundColor,
      textColor: Theme.of(context).colorScheme.toastTextColor,
      fontSize: 16.0,
    );
  } on MissingPluginException catch (_) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Theme.of(context).colorScheme.toastBackgroundColor,
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.toastTextColor,
          fontSize: 16.0,
        ),
      ),
    );

    final fToast = FToast();
    fToast.init(context);

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 2),
    );
  }
}

void showShortToast(context, String message) {
  showToast(context, message, toastLength: Toast.LENGTH_SHORT);
}
