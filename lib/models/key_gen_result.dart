import "dart:typed_data";

import 'package:photos/models/key_attributes.dart';
import 'package:photos/models/private_key_attributes.dart';

class KeyGenResult {
  final KeyAttributes keyAttributes;
  final PrivateKeyAttributes privateKeyAttributes;
  final Uint8List loginKey;

  KeyGenResult(this.keyAttributes, this.privateKeyAttributes, this.loginKey);
}
