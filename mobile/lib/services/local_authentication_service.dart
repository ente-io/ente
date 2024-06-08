import "dart:async";

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/dialog_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/settings/TEMP/lock_screen_option_password.dart";
import "package:photos/ui/settings/TEMP/lock_screen_option_pin.dart";
import 'package:photos/ui/tools/app_lock.dart';
import 'package:photos/utils/auth_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

class LocalAuthenticationService {
  LocalAuthenticationService._privateConstructor();
  static final LocalAuthenticationService instance =
      LocalAuthenticationService._privateConstructor();

  final Configuration _configuration = Configuration.instance;

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

  Future<bool> requestEnteAuthForLockScreen(BuildContext context) async {
    final String? savedPin = await _configuration.loadSavedPin();
    final String? savedPassword = await _configuration.loadSavedPassword();

    if (savedPassword != null) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return LockScreenOptionPassword(
              isAuthenticating: true,
              authPass: savedPassword,
            );
          },
        ),
      );
      if (result) {
        return true;
      } else {
        await showDialogWidget(
          context: context,
          title: 'Password does not match',
          icon: Icons.lock,
          body: 'Please re-enter the password.',
          isDismissible: true,
          buttons: [
            ButtonWidget(
              buttonType: ButtonType.secondary,
              labelText: S.of(context).ok,
              isInAlert: true,
              buttonAction: ButtonAction.first,
            ),
          ],
        );
        return false;
      }
    }
    if (savedPin != null) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return LockScreenOptionPin(
              isAuthenticating: true,
              authPin: savedPin,
            );
          },
        ),
      );
      if (result) {
        return true;
      } else {
        await showDialogWidget(
          context: context,
          title: 'Pin does not match',
          icon: Icons.lock,
          body: 'Please re-enter the pin.',
          isDismissible: true,
          buttons: [
            ButtonWidget(
              buttonType: ButtonType.secondary,
              labelText: S.of(context).ok,
              isInAlert: true,
              buttonAction: ButtonAction.first,
            ),
          ],
        );
        return false;
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
    // if (await requestEnteAuthForLockScreen(context)) {
    //   return true;
    // }

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
