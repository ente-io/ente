import 'dart:typed_data';
import 'dart:convert';
import 'sodium.dart';

/// Computes an authentication tag for a message and a secret key, and provides a way to verify that a given tag is valid for a given message and a key.
class CryptoAuth {
  /// Generates a random key for use with authentication.
  static Uint8List randomKey() => Sodium.cryptoAuthKeygen();

  /// Computes a tag for given value and key.
  static Uint8List compute(Uint8List value, Uint8List key) =>
      Sodium.cryptoAuth(value, key);

  /// Verifies that the tag is valid for given value and key.
  static bool verify(Uint8List tag, Uint8List value, Uint8List key) =>
      Sodium.cryptoAuthVerify(tag, value, key);

  /// Computes a tag for given string value and key.
  static Uint8List computeString(String value, Uint8List key) =>
      compute(utf8.encoder.convert(value), key);

  /// Verifies that the tag is valid for given string value and key.
  static bool verifyString(Uint8List tag, String value, Uint8List key) =>
      verify(tag, utf8.encoder.convert(value), key);
}
