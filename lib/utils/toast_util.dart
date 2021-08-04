import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';

Future<void> showToast(String message, {toastLength = Toast.LENGTH_LONG}) async {
  if (Platform.isAndroid) {
    await Fluttertoast.cancel();
    return Fluttertoast.showToast(
        msg: message,
        toastLength: toastLength,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blueGrey[900],
        textColor: Colors.white,
        fontSize: 16.0);
  } else {
    EasyLoading.instance
      ..backgroundColor = Colors.blueGrey[900]
      ..indicatorColor = Colors.blueGrey[900]
      ..textColor = Colors.white
      ..userInteractions = true
      ..loadingStyle = EasyLoadingStyle.custom;
    return EasyLoading.showToast(
      message,
      duration: Duration(seconds: (toastLength == Toast.LENGTH_LONG ? 5 : 3)),
      toastPosition: EasyLoadingToastPosition.bottom,
    );
  }
}
