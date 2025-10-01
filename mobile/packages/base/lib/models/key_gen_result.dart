import "dart:typed_data";

import 'package:ente_base/models/key_attributes.dart';
import 'package:ente_base/models/private_key_attributes.dart';

class KeyGenResult {
  final KeyAttributes keyAttributes;
  final PrivateKeyAttributes privateKeyAttributes;
  final Uint8List loginKey;

  KeyGenResult(this.keyAttributes, this.privateKeyAttributes, this.loginKey);
}
