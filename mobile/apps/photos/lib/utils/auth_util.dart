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
          biometricHint: AppLocalizations.of(context).androidBiometricHint,
          biometricNotRecognized:
              AppLocalizations.of(context).androidBiometricNotRecognized,
          biometricRequiredTitle:
              AppLocalizations.of(context).androidBiometricRequiredTitle,
          biometricSuccess:
              AppLocalizations.of(context).androidBiometricSuccess,
          cancelButton: AppLocalizations.of(context).androidCancelButton,
          deviceCredentialsRequiredTitle: AppLocalizations.of(context)
              .androidDeviceCredentialsRequiredTitle,
          deviceCredentialsSetupDescription: AppLocalizations.of(context)
              .androidDeviceCredentialsSetupDescription,
          goToSettingsButton: AppLocalizations.of(context).goToSettings,
          goToSettingsDescription:
              AppLocalizations.of(context).androidGoToSettingsDescription,
          signInTitle: AppLocalizations.of(context).androidSignInTitle,
        ),
        IOSAuthMessages(
          localizedFallbackTitle: AppLocalizations.of(context).enterPassword,
          goToSettingsButton: AppLocalizations.of(context).goToSettings,
          goToSettingsDescription: AppLocalizations.of(context).goToSettings,
          lockOut: AppLocalizations.of(context).iOSLockOut,
          // cancelButton default value is "Ok"
          cancelButton: AppLocalizations.of(context).iOSOkButton,
        ),
      ],
    );
  }
}
