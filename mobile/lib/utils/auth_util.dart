import "package:flutter/widgets.dart";
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';
import 'package:logging/logging.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/services/local_authentication_service.dart";
import "package:photos/utils/lock_screen_settings.dart";

Future<bool> requestAuthentication(
  BuildContext context,
  String reason, {
  bool isOpeningApp = false,
  bool isAuthenticatingForInAppChange = false,
}) async {
  Logger("AuthUtil").info("Requesting authentication");
  await LocalAuthentication().stopAuthentication();

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
  } else {
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
          localizedFallbackTitle: S.of(context).enterPassword,
          goToSettingsButton: S.of(context).goToSettings,
          goToSettingsDescription: S.of(context).goToSettings,
          lockOut: S.of(context).iOSLockOut,
          // cancelButton default value is "Ok"
          cancelButton: S.of(context).iOSOkButton,
        ),
      ],
    );
  }
}
