import "package:dio/dio.dart";

/// Gateway for passkey-related API endpoints.
///
/// Handles passkey authentication, recovery configuration, and account token
/// retrieval for the Ente accounts portal.
class PasskeyGateway {
  final Dio _enteDio;

  PasskeyGateway(this._enteDio);

  /// Get accounts token for passkey management.
  ///
  /// Returns a map containing:
  /// - `accountsUrl`: The base URL for accounts portal (or null to use default)
  /// - `accountsToken`: JWT token for authenticating with the accounts portal
  ///
  /// Endpoint: GET /users/accounts-token
  Future<Map<String, dynamic>> getAccountsToken() async {
    final response = await _enteDio.get("/users/accounts-token");
    return response.data as Map<String, dynamic>;
  }

  /// Check if passkey recovery is enabled for the user.
  ///
  /// Returns true if the user has configured passkey recovery, false otherwise.
  ///
  /// Endpoint: GET /users/two-factor/recovery-status
  Future<bool> isPasskeyRecoveryEnabled() async {
    final response = await _enteDio.get("/users/two-factor/recovery-status");
    return response.data["isPasskeyRecoveryEnabled"] as bool;
  }

  /// Configure passkey recovery for the user.
  ///
  /// Parameters:
  /// - [secret]: The recovery secret
  /// - [userSecretCipher]: The encrypted user secret
  /// - [userSecretNonce]: The nonce used for encrypting the user secret
  ///
  /// Endpoint: POST /users/two-factor/passkeys/configure-recovery
  Future<void> configurePasskeyRecovery({
    required String secret,
    required String userSecretCipher,
    required String userSecretNonce,
  }) async {
    await _enteDio.post(
      "/users/two-factor/passkeys/configure-recovery",
      data: {
        "secret": secret,
        "userSecretCipher": userSecretCipher,
        "userSecretNonce": userSecretNonce,
      },
    );
  }
}
