import 'dart:typed_data';

class DerivedKeyResult {
  final Uint8List key;
  final Uint8List salt;

  DerivedKeyResult(this.key, this.salt);
}
