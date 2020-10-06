import 'dart:typed_data';

class ChaChaEncryptionResult {
  final Uint8List encryptedData;
  final Uint8List header;

  ChaChaEncryptionResult(this.encryptedData, this.header);
}