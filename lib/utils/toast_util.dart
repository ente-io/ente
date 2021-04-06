import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

Future<void> showToast(String message, {toastLength: Toast.LENGTH_LONG}) {
  return Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.blueGrey[900],
      textColor: Colors.white,
      fontSize: 16.0);
}
