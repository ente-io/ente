import "dart:typed_data";

import "package:ente_crypto/ente_crypto.dart";

class CollectionFileRequest {
  final int id;
  final String encryptedKey;
  final String keyDecryptionNonce;

  CollectionFileRequest(
    this.id,
    this.encryptedKey,
    this.keyDecryptionNonce,
  );

  static Map<String, dynamic> req(
    int id, {
    required Uint8List encKey,
    required Uint8List encKeyNonce,
  }) {
    return {
      'id': id,
      'encryptedKey': CryptoUtil.bin2base64(encKey),
      'keyDecryptionNonce': CryptoUtil.bin2base64(encKeyNonce),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'encryptedKey': encryptedKey,
      'keyDecryptionNonce': keyDecryptionNonce,
    };
  }
}
