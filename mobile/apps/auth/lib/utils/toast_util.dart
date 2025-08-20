import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast(
  BuildContext context,
  String message, {
  toastLength = Toast.LENGTH_LONG,
  iOSDismissOnTap = true,
}) async {
  // If on mobile render toast above the keyboard using FToast.
  final bool isMobile = PlatformUtil.isMobile();

  if (isMobile) {
    final baseToast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Theme.of(context).colorScheme.toastBackgroundColor,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.toastTextColor,
          fontSize: 16.0,
        ),
      ),
    );

    final fToast = FToast()..init(context);

    Widget toastChild = baseToast;
    if (iOSDismissOnTap == true) {
      toastChild = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          fToast.removeCustomToast();
          fToast.removeQueuedCustomToasts();
        },
        child: baseToast,
      );
    }

    fToast.showToast(
      child: toastChild,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 2),
      positionedToastBuilder: (context, child, _) {
        final double currentInset = MediaQuery.of(context).viewInsets.bottom;
        return Positioned(
          left: 16,
          right: 16,
          bottom: currentInset + 16,
          child: child,
        );
      },
    );
    return;
  }

  // Default path (desktop)
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
    final fToast = FToast()..init(context);
    final Widget baseToast = Container(
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

    fToast.showToast(
      child: baseToast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 2),
    );
  }
}

void showShortToast(BuildContext context, String message) {
  showToast(context, message, toastLength: Toast.LENGTH_SHORT);
}
