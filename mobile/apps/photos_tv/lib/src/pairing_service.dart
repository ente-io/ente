import 'dart:convert';

import 'package:ente_crypto_api/ente_crypto_api.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'http_util.dart';
import 'models.dart';

/// Service that registers this TV and fetches cast payloads.
class PairingService {
  final http.Client _client;

  /// Creates pairing service.
  PairingService(this._client);

  /// Registers this TV for pairing.
  Future<Registration> register() async {
    final keyPair = CryptoUtil.generateKeyPair();
    final publicKey = CryptoUtil.bin2base64(keyPair.publicKey);
    final pairingCode = await _registerDevice(publicKey);
    return Registration(
      pairingCode: pairingCode,
      publicKey: publicKey,
      privateKey: CryptoUtil.bin2base64(keyPair.secretKey),
    );
  }

  /// Fetches decrypted cast payload for registration.
  Future<CastPayload?> getCastPayload(Registration registration) async {
    final encryptedCastData = await _getEncryptedCastData(
      registration.pairingCode,
    );
    if (encryptedCastData == null) return null;
    final payloadBytes = CryptoUtil.openSealSync(
      CryptoUtil.base642bin(encryptedCastData),
      CryptoUtil.base642bin(registration.publicKey),
      CryptoUtil.base642bin(registration.privateKey),
    );
    return CastPayload.fromJson(jsonDecode(utf8.decode(payloadBytes)));
  }

  /// Closes HTTP resources.
  void close() => _client.close();

  Future<String> _registerDevice(String publicKey) async {
    final response = await _client.post(
      Uri.parse('$apiOrigin/cast/device-info'),
      headers: jsonHeaders,
      body: jsonEncode({'publicKey': publicKey}),
    );
    ensureOk(response);
    return jsonDecode(response.body)['deviceCode'] as String;
  }

  Future<String?> _getEncryptedCastData(String code) async {
    final response = await _client.get(
      Uri.parse('$apiOrigin/cast/cast-data/$code'),
      headers: jsonHeaders,
    );
    ensureOk(response);
    return jsonDecode(response.body)['encCastData'] as String?;
  }
}
