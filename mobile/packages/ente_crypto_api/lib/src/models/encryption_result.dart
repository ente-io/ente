import 'dart:typed_data';

class EncryptionResult {
  final Uint8List? encryptedData;
  final Uint8List? key;
  final Uint8List? header;
  final Uint8List? nonce;

  const EncryptionResult({
    this.encryptedData,
    this.key,
    this.header,
    this.nonce,
  });
}

class FileEncryptResult {
  final Uint8List key;
  final Uint8List header;
  final String? fileMd5;
  final List<String>? partMd5s;
  final int? partSize;

  const FileEncryptResult({
    required this.key,
    required this.header,
    this.fileMd5,
    this.partMd5s,
    this.partSize,
  });
}
