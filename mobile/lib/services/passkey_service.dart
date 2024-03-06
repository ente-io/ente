import "package:flutter/cupertino.dart";
import "package:logging/logging.dart";
import "package:photos/core/network/network.dart";
import "package:photos/utils/dialog_util.dart";
import 'package:url_launcher/url_launcher_string.dart';

class PasskeyService {
  PasskeyService._privateConstructor();
  static final PasskeyService instance = PasskeyService._privateConstructor();

  final _enteDio = NetworkClient.instance.enteDio;

  Future<String> getJwtToken() async {
    final response = await _enteDio.get(
      "/users/accounts-token",
    );
    return response.data!["accountsToken"] as String;
  }

  Future<void> openPasskeyPage(BuildContext context) async {
    try {
      final jwtToken = await getJwtToken();
      final url = "https://accounts.ente.io/account-handoff?token=$jwtToken";
      await launchUrlString(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      Logger('PasskeyService').severe("failed to open passkey page", e);
      showGenericErrorDialog(context: context, error: e).ignore();
    }
  }
}
