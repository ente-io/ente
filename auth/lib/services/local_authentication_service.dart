import 'dart:io';

import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/ui/tools/app_lock.dart';
import 'package:ente_auth/utils/auth_util.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
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

  Future<bool> requestLocalAuthentication(
    BuildContext context,
    String infoMessage,
  ) async {
    if (await _isLocalAuthSupportedOnDevice()) {
      AppLock.of(context)!.setEnabled(false);
      final result = await requestAuthentication(context, infoMessage);
      AppLock.of(context)!.setEnabled(
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
      AppLock.of(context)!.disable();
      final result = await requestAuthentication(
        context,
        infoMessage,
      );
      if (result) {
        AppLock.of(context)!.setEnabled(shouldEnableLockScreen);
        await Configuration.instance
            .setShouldShowLockScreen(shouldEnableLockScreen);
        return true;
      } else {
        AppLock.of(context)!
            .setEnabled(Configuration.instance.shouldShowLockScreen());
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

  Future<bool> _isLocalAuthSupportedOnDevice() async {
    try {
      return Platform.isMacOS || Platform.isLinux
          ? await FlutterLocalAuthentication().canAuthenticate()
          : await LocalAuthentication().isDeviceSupported();
    } on MissingPluginException {
      return false;
    }
  }
}
