import "dart:async";

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/notification/toast.dart';
import "package:photos/ui/settings/lock_screen/lock_screen_password.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_pin.dart";
import 'package:photos/ui/tools/app_lock.dart';
import 'package:photos/utils/auth_util.dart';
import 'package:photos/utils/dialog_util.dart';

class LocalAuthenticationService {
  LocalAuthenticationService._privateConstructor();
  static final LocalAuthenticationService instance =
      LocalAuthenticationService._privateConstructor();

  Future<bool> requestLocalAuthentication(
    BuildContext context,
    String infoMessage,
  ) async {
    if (await _isLocalAuthSupportedOnDevice()) {
      AppLock.of(context)!.setEnabled(false);
      final result = await requestAuthentication(
        context,
        infoMessage,
        isAuthenticatingForInAppChange: true,
      );
      AppLock.of(context)!.setEnabled(
        await Configuration.instance.shouldShowLockScreen(),
      );
      if (!result) {
        showToast(context, infoMessage);
        return false;
      } else {
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
    if (await _isLocalAuthSupportedOnDevice()) {
      AppLock.of(context)!.disable();
      final result = await requestAuthentication(
        context,
        infoMessage,
      );
      if (result) {
        AppLock.of(context)!.setEnabled(shouldEnableLockScreen);

        await Configuration.instance
            .setSystemLockScreen(shouldEnableLockScreen);
        return true;
      } else {
        AppLock.of(context)!
            .setEnabled(await Configuration.instance.shouldShowLockScreen());
      }
    } else {
      unawaited(
        showErrorDialog(
          context,
          errorDialogTitle,
          errorDialogContent,
        ),
      );
    }
    return false;
  }

  Future<bool> _isLocalAuthSupportedOnDevice() async {
    return LocalAuthentication().isDeviceSupported();
  }
}
