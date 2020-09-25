import 'dart:typed_data';

import 'package:flutter_sodium/flutter_sodium.dart';

class EncryptionAttribute {
  String base64;
  Uint8List bytes;

  EncryptionAttribute({this.base64, this.bytes}) {
    if (base64 != null) {
      this.bytes = Sodium.base642bin(base64);
    } else {
      this.base64 = Sodium.bin2base64(bytes);
    }
  }
}
