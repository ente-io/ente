import 'package:local_auth/auth_strings.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';

Future<bool> requestAuthentication(String reason) async {
  Logger("AuthUtil").info("Requesting authentication");
  await LocalAuthentication().stopAuthentication();
  return await LocalAuthentication().authenticate(
    localizedReason: reason,
    androidAuthStrings: const AndroidAuthMessages(
      biometricHint: "Verify identity",
      biometricNotRecognized: "Not recognized, try again",
      biometricRequiredTitle: "Biometric required",
      biometricSuccess: "Successfully verified",
      cancelButton: "Cancel",
      deviceCredentialsRequiredTitle: "Device credentials required",
      deviceCredentialsSetupDescription: "Device credentials required",
      goToSettingsButton: "Go to settings",
      goToSettingsDescription:
          "Authentication is not setup on your device, go to Settings > Security to set it up",
      signInTitle: "Authentication required",
    ),
  );
}
