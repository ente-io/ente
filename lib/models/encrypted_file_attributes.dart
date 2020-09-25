import 'dart:typed_data';

class EncryptedFileAttributes {
  final Uint8List key;
  final Uint8List header;

  EncryptedFileAttributes(this.key, this.header);
}
