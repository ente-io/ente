import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';

Future<bool> requestAuthentication(String reason) async {
  Logger("AuthUtil").info("Requesting authentication");
  await LocalAuthentication().stopAuthentication();
  return await LocalAuthentication().authenticate(
    localizedReason: reason,
  );
}
