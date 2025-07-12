import "dart:typed_data";

import 'key_attributes.dart';
import 'private_key_attributes.dart';

class KeyGenResult {
  final KeyAttributes keyAttributes;
  final PrivateKeyAttributes privateKeyAttributes;
  final Uint8List loginKey;

  KeyGenResult(this.keyAttributes, this.privateKeyAttributes, this.loginKey);
}
