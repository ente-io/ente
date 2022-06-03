import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';

Future<void> showToast(String message,
    {toastLength = Toast.LENGTH_LONG}) async {
  if (Platform.isAndroid) {
    await Fluttertoast.cancel();
    return Fluttertoast.showToast(
        msg: message,
        toastLength: toastLength,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: Color.fromRGBO(127, 127, 127, 0.5),
        textColor: Colors.white,
        fontSize: 16.0);
  } else {
    EasyLoading.instance
      ..backgroundColor = Color.fromRGBO(127, 127, 127, 0.5)
      ..indicatorColor = Color.fromRGBO(127, 127, 127, 0.5)
      ..textColor = Colors.white
      ..userInteractions = true
      ..loadingStyle = EasyLoadingStyle.custom;
    return EasyLoading.showToast(
      message,
      duration: Duration(seconds: (toastLength == Toast.LENGTH_LONG ? 5 : 2)),
      toastPosition: EasyLoadingToastPosition.bottom,
    );
  }
}

Future<void> showShortToast(String message) {
  return showToast(message, toastLength: Toast.LENGTH_SHORT);
}
