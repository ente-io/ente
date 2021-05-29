import 'dart:convert';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'sodium.dart';

/// Secret-key single-message authentication using Poly1305.
class OnetimeAuth {
  /// Generates a random key for use in onetime authentication.
  static Uint8List randomKey() => Sodium.cryptoOnetimeauthKeygen();

  /// Computes a tag for given value and key.
  static Uint8List compute(Uint8List value, Uint8List key) =>
      Sodium.cryptoOnetimeauth(value, key);

  /// Verifies that the tag is valid for given value and key.
  static bool verify(Uint8List tag, Uint8List value, Uint8List key) =>
      Sodium.cryptoOnetimeauthVerify(tag, value, key);

  /// Computes a tag for given string value and key.
  static Uint8List computeString(String value, Uint8List key) =>
      compute(utf8.encoder.convert(value), key);

  /// Verifies that the tag is valid for given string value and key.
  static bool verifyString(Uint8List tag, String value, Uint8List key) =>
      verify(tag, utf8.encoder.convert(value), key);

  // Computes a tag for given stream of strings and key.
  static Future<Uint8List> computeStrings(
      Stream<String> stream, Uint8List key) async {
    final state = Sodium.cryptoOnetimeauthInit(key);
    try {
      await for (var value in stream) {
        Sodium.cryptoOnetimeauthUpdate(state, utf8.encoder.convert(value));
      }
      return Sodium.cryptoOnetimeauthFinal(state);
    } finally {
      calloc.free(state);
    }
  }
}
