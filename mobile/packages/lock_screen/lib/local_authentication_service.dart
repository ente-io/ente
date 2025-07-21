import 'dart:io';

import 'package:ente_lock_screen/auth_util.dart';
import 'package:ente_lock_screen/lock_screen_settings.dart';
import 'package:ente_lock_screen/ui/app_lock.dart';
import 'package:ente_lock_screen/ui/lock_screen_password.dart';
import 'package:ente_lock_screen/ui/lock_screen_pin.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:ente_ui/utils/toast_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_authentication/flutter_local_authentication.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';

class LocalAuthenticationService {
  LocalAuthenticationService._privateConstructor();
  static final LocalAuthenticationService instance =
      LocalAuthenticationService._privateConstructor();
  final logger = Logger((LocalAuthenticationService).toString());
  int lastAuthTime = 0;

  Future<bool> requestLocalAuthentication(
    BuildContext context,
    String infoMessage,
  ) async {
    if (kDebugMode) {
      // if last auth time is less than 60 seconds, don't ask for auth again
      if (lastAuthTime != 0 &&
          DateTime.now().millisecondsSinceEpoch - lastAuthTime < 60000) {
        return true;
      }
    }
    if (await isLocalAuthSupportedOnDevice() ||
        LockScreenSettings.instance.getIsAppLockSet()) {
      AppLock.of(context)!.setEnabled(false);
      final result = await requestAuthentication(
        context,
        infoMessage,
        isAuthenticatingForInAppChange: true,
      );
      AppLock.of(context)!.setEnabled(
        await LockScreenSettings.instance.shouldShowLockScreen(),
      );
      if (!result) {
        showToast(context, infoMessage);
        return false;
      } else {
        lastAuthTime = DateTime.now().millisecondsSinceEpoch;
        return true;
      }
    }
    return true;
  }

  Future<bool> requestEnteAuthForLockScreen(
    BuildContext context,
    String? savedPin,
    String? savedPassword, {
    bool isAuthenticatingOnAppLaunch = false,
    bool isAuthenticatingForInAppChange = false,
  }) async {
    if (savedPassword != null) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return LockScreenPassword(
              isChangingLockScreenSettings: true,
              isAuthenticatingForInAppChange: isAuthenticatingForInAppChange,
              isAuthenticatingOnAppLaunch: isAuthenticatingOnAppLaunch,
              authPass: savedPassword,
            );
          },
        ),
      );
      if (result) {
        return true;
      }
    }
    if (savedPin != null) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return LockScreenPin(
              isChangingLockScreenSettings: true,
              isAuthenticatingForInAppChange: isAuthenticatingForInAppChange,
              isAuthenticatingOnAppLaunch: isAuthenticatingOnAppLaunch,
              authPin: savedPin,
            );
          },
        ),
      );
      if (result) {
        return true;
      }
    }
    return false;
  }

  Future<bool> requestLocalAuthForLockScreen(
    BuildContext context,
    bool shouldEnableLockScreen,
    String infoMessage,
    String errorDialogContent, [
    String errorDialogTitle = "",
  ]) async {
    if (await isLocalAuthSupportedOnDevice()) {
      AppLock.of(context)!.disable();
      final result = await requestAuthentication(
        context,
        infoMessage,
      );
      if (result) {
        AppLock.of(context)!.setEnabled(shouldEnableLockScreen);
        await LockScreenSettings.instance
            .setSystemLockScreen(shouldEnableLockScreen);
        return true;
      } else {
        AppLock.of(context)!.setEnabled(
          await LockScreenSettings.instance.shouldShowLockScreen(),
        );
      }
    } else {
      // ignore: unawaited_futures
      showErrorDialog(
        context,
        errorDialogTitle,
        errorDialogContent,
      );
    }
    return false;
  }

  Future<bool> isLocalAuthSupportedOnDevice() async {
    try {
      return Platform.isLinux
          ? await FlutterLocalAuthentication().canAuthenticate()
          : await LocalAuthentication().isDeviceSupported();
    } on MissingPluginException {
      return false;
    }
  }
}
