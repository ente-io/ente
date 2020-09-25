import 'package:photos/models/encryption_attribute.dart';

class EncryptedData {
  final EncryptionAttribute key;
  final EncryptionAttribute nonce;
  final EncryptionAttribute encryptedData;

  EncryptedData(this.key, this.nonce, this.encryptedData);
}
