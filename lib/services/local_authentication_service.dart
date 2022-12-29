// @dart=2.9

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/components/dialog_widget.dart';
import 'package:photos/ui/tools/app_lock.dart';
import 'package:photos/utils/auth_util.dart';
import 'package:photos/utils/toast_util.dart';

class LocalAuthenticationService {
  LocalAuthenticationService._privateConstructor();
  static final LocalAuthenticationService instance =
      LocalAuthenticationService._privateConstructor();

  Future<bool> requestLocalAuthentication(
    BuildContext context,
    String infoMessage,
  ) async {
    if (await _isLocalAuthSupportedOnDevice()) {
      AppLock.of(context).setEnabled(false);
      final result = await requestAuthentication(infoMessage);
      AppLock.of(context).setEnabled(
        Configuration.instance.shouldShowLockScreen(),
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

  Future<bool> requestLocalAuthForLockScreen(
    BuildContext context,
    bool shouldEnableLockScreen,
    String infoMessage,
    String errorDialogContent, [
    String errorDialogTitle = "",
  ]) async {
    if (await _isLocalAuthSupportedOnDevice()) {
      AppLock.of(context).disable();
      final result = await requestAuthentication(
        infoMessage,
      );
      if (result) {
        AppLock.of(context).setEnabled(shouldEnableLockScreen);
        await Configuration.instance
            .setShouldShowLockScreen(shouldEnableLockScreen);
        return true;
      } else {
        AppLock.of(context)
            .setEnabled(Configuration.instance.shouldShowLockScreen());
      }
    } else {
      showErrorDialog(
        context,
        errorDialogTitle,
        errorDialogContent,
      );
    }
    return false;
  }

  Future<bool> _isLocalAuthSupportedOnDevice() async {
    return LocalAuthentication().isDeviceSupported();
  }
}
