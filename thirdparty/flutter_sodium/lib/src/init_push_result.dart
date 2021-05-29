import 'dart:ffi';
import 'dart:typed_data';

class InitPushResult {
  final Pointer<Uint8> state;
  final Uint8List header;

  const InitPushResult({required this.state, required this.header});
}
