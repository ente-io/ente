import 'dart:io';

import 'package:ente_lock_screen/local_authentication_service.dart';
import 'package:ente_lock_screen/lock_screen_settings.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_authentication/flutter_local_authentication.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/types/auth_messages_ios.dart';
import 'package:logging/logging.dart';

Future<bool> requestAuthentication(
  BuildContext context,
  String reason, {
  bool isOpeningApp = false,
  bool isAuthenticatingForInAppChange = false,
}) async {
  Logger("AuthUtil").info("Requesting authentication");

  final String? savedPin = await LockScreenSettings.instance.getPin();
  final String? savedPassword = await LockScreenSettings.instance.getPassword();
  if (savedPassword != null || savedPin != null) {
    return await LocalAuthenticationService.instance
        .requestEnteAuthForLockScreen(
      context,
      savedPin,
      savedPassword,
      isAuthenticatingOnAppLaunch: isOpeningApp,
      isAuthenticatingForInAppChange: isAuthenticatingForInAppChange,
    );
  }
  if (Platform.isMacOS || Platform.isLinux) {
    return await FlutterLocalAuthentication().authenticate();
  } else {
    await LocalAuthentication().stopAuthentication();
    final l10n = context.strings;
    return await LocalAuthentication().authenticate(
      localizedReason: reason,
      authMessages: [
        AndroidAuthMessages(
          biometricHint: l10n.androidBiometricHint,
          biometricNotRecognized: l10n.androidBiometricNotRecognized,
          biometricRequiredTitle: l10n.androidBiometricRequiredTitle,
          biometricSuccess: l10n.androidBiometricSuccess,
          cancelButton: l10n.androidCancelButton,
          deviceCredentialsRequiredTitle:
              l10n.androidDeviceCredentialsRequiredTitle,
          deviceCredentialsSetupDescription:
              l10n.androidDeviceCredentialsSetupDescription,
          goToSettingsButton: l10n.goToSettings,
          goToSettingsDescription: l10n.androidGoToSettingsDescription,
          signInTitle: l10n.androidSignInTitle,
        ),
        IOSAuthMessages(
          goToSettingsButton: l10n.goToSettings,
          goToSettingsDescription: l10n.goToSettings,
          lockOut: l10n.iOSLockOut,
          // cancelButton default value is "Ok"
          cancelButton: l10n.iOSOkButton,
        ),
      ],
    );
  }
}
