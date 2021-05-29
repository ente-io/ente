import 'dart:typed_data';

/// Represents a secret key and a corresponding public key.
class KeyPair {
  final Uint8List pk, sk;

  const KeyPair({required this.pk, required this.sk});
}
