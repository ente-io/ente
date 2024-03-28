import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_authentication/flutter_local_authentication.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/types/auth_messages_ios.dart';
import 'package:logging/logging.dart';

Future<bool> requestAuthentication(BuildContext context, String reason) async {
  Logger("AuthUtil").info("Requesting authentication");
  if (Platform.isMacOS || Platform.isLinux) {
    return await FlutterLocalAuthentication().authenticate();
  } else {
    await LocalAuthentication().stopAuthentication();
    final l10n = context.l10n;
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
