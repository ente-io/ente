import 'dart:typed_data';
import 'dart:convert';
import 'sodium.dart';

/// Derive secret subkeys from a single master key.
class KeyDerivation {
  /// Generates a random master key for use with key derivation.
  static Uint8List randomKey() => Sodium.cryptoKdfKeygen();

  /// Derives a subkey from given master key.
  static Uint8List derive(Uint8List masterKey, int subKeyId,
      {int? subKeyLength, String context = '00000000'}) {
    subKeyLength ??= Sodium.cryptoKdfBytesMin;
    return Sodium.cryptoKdfDeriveFromKey(
        subKeyLength, subKeyId, utf8.encoder.convert(context), masterKey);
  }
}
