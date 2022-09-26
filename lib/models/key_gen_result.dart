import 'package:photos/models/key_attributes.dart';
import 'package:photos/models/private_key_attributes.dart';

class KeyGenResult {
  final KeyAttributes keyAttributes;
  final PrivateKeyAttributes privateKeyAttributes;

  KeyGenResult(this.keyAttributes, this.privateKeyAttributes);
}
