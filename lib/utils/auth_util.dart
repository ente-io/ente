import 'package:local_auth/auth_strings.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';

Future<bool> requestAuthentication() async {
  Logger("AuthUtil").info("Requesting authentication");
  await LocalAuthentication().stopAuthentication();
  return await LocalAuthentication().authenticate(
    localizedReason: "please authenticate to view your memories",
    androidAuthStrings: AndroidAuthMessages(
      biometricHint: "verify identity",
      biometricNotRecognized: "not recognized, try again",
      biometricRequiredTitle: "biometric required",
      biometricSuccess: "successfully verified",
      cancelButton: "cancel",
      deviceCredentialsRequiredTitle: "device credentials required",
      deviceCredentialsSetupDescription: "device credentials required",
      goToSettingsButton: "go to settings",
      goToSettingsDescription:
          "authentication is not setup on your device, go to Settings > Security to set it up",
      signInTitle: "authentication required",
    ),
  );
}
