import 'dart:typed_data';

/// Detached cipher and associated authentication tag.
class DetachedCipher {
  final Uint8List c, mac;

  const DetachedCipher({required this.c, required this.mac});
}
