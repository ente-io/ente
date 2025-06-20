import "dart:typed_data";

import "package:ente_crypto/ente_crypto.dart";

class CollectionFileItem {
  final int id;
  final String encryptedKey;
  final String keyDecryptionNonce;

  CollectionFileItem(
    this.id,
    this.encryptedKey,
    this.keyDecryptionNonce,
  );

  static Map<String, dynamic> req(
    int fileID, {
    required Uint8List encryptedKey,
    required Uint8List keyDecryptionNonce,
  }) {
    return {
      'fileID': fileID,
      'encryptedKey': CryptoUtil.bin2base64(encryptedKey),
      'keyDecryptionNonce': CryptoUtil.bin2base64(keyDecryptionNonce),
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
