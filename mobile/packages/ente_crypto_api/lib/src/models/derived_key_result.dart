import 'dart:typed_data';

class DerivedKeyResult {
  final Uint8List key;
  final int memLimit;
  final int opsLimit;

  const DerivedKeyResult(this.key, this.memLimit, this.opsLimit);
}
