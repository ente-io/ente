import 'dart:typed_data';

class EncryptedData {
  final Uint8List key;
  final Uint8List nonce;
  final Uint8List encryptedData;

  EncryptedData(this.key, this.nonce, this.encryptedData);
}
