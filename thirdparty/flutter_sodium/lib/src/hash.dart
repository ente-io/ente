import 'dart:convert';
import 'dart:typed_data';
import 'sodium.dart';

/// SHA-512 hash functions.
class Hash {
  /// Computes a hash for given value.
  static Uint8List hash(Uint8List value) => Sodium.cryptoHash(value);

  /// Computes a hash for given string value.
  static Uint8List hashString(String value) =>
      hash(utf8.encoder.convert(value));
}
