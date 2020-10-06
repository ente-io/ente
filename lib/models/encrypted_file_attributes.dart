import 'dart:typed_data';

class ChaChaAttributes {
  final Uint8List key;
  final Uint8List header;

  ChaChaAttributes(this.key, this.header);
}
