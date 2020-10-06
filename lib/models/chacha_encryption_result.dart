import 'dart:typed_data';

class ChaChaEncryptionResult {
  final Uint8List encryptedData;
  final Uint8List header;
  final Uint8List nonce;

  ChaChaEncryptionResult(this.encryptedData, {this.header, this.nonce});
}
