import 'package:photos/models/encryption_attribute.dart';

class ChaChaAttributes {
  final EncryptionAttribute key;
  final EncryptionAttribute header;

  ChaChaAttributes(this.key, this.header);
}
