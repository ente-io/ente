import 'package:ente_auth/models/key_attributes.dart';
import 'package:ente_auth/models/private_key_attributes.dart';

class KeyGenResult {
  final KeyAttributes keyAttributes;
  final PrivateKeyAttributes privateKeyAttributes;

  KeyGenResult(this.keyAttributes, this.privateKeyAttributes);
}
