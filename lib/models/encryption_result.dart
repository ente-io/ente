import 'dart:typed_data';

class EncryptionResult {
  final Uint8List? encryptedData;
  final Uint8List? key;
  final Uint8List? header;
  final Uint8List? nonce;

  EncryptionResult({
    this.encryptedData,
    this.key,
    this.header,
    this.nonce,
  });
}
