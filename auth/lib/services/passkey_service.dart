import 'package:ente_auth/core/network.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PasskeyService {
  PasskeyService._privateConstructor();
  static final PasskeyService instance = PasskeyService._privateConstructor();

  final _enteDio = Network.instance.enteDio;

  Future<String?> getJwtToken() async {
    try {
      final response = await _enteDio.get(
        "/users/accounts-token",
      );
      if (response.data?["accountsToken"] == null) return null;
      return response.data["accountsToken"] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<void> openPasskeyPage() async {
    final jwtToken = await getJwtToken();

    final url = jwtToken != null
        ? "https://accounts.ente.io/account-handoff?token=$jwtToken"
        : "https://accounts.ente.io/";
    await launchUrlString(
      url,
      mode: LaunchMode.externalApplication,
    );
  }
}
