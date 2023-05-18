import "package:flutter/widgets.dart";
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';
import 'package:logging/logging.dart';
import "package:photos/generated/l10n.dart";

Future<bool> requestAuthentication(BuildContext context, String reason) async {
  Logger("AuthUtil").info("Requesting authentication");
  await LocalAuthentication().stopAuthentication();

  return await LocalAuthentication().authenticate(
    localizedReason: reason,
    authMessages: [
      AndroidAuthMessages(
        biometricHint: S.of(context).androidBiometricHint,
        biometricNotRecognized: S.of(context).androidBiometricNotRecognized,
        biometricRequiredTitle: S.of(context).androidBiometricRequiredTitle,
        biometricSuccess: S.of(context).androidBiometricSuccess,
        cancelButton: S.of(context).androidCancelButton,
        deviceCredentialsRequiredTitle:
            S.of(context).androidDeviceCredentialsRequiredTitle,
        deviceCredentialsSetupDescription:
            S.of(context).androidDeviceCredentialsSetupDescription,
        goToSettingsButton: S.of(context).goToSettings,
        goToSettingsDescription: S.of(context).androidGoToSettingsDescription,
        signInTitle: S.of(context).androidSignInTitle,
      ),
      IOSAuthMessages(
        goToSettingsButton: S.of(context).goToSettings,
        goToSettingsDescription: S.of(context).goToSettings,
        lockOut: S.of(context).iOSLockOut,
        // cancelButton default value is "Ok"
        cancelButton: S.of(context).iOSOkButton,
      ),
    ],
  );
}
