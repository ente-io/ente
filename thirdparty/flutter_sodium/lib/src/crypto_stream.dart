import 'dart:typed_data';
import 'dart:convert';
import 'sodium.dart';

/// Generate deterministic streams of random data based off a secret key and random nonce.
class CryptoStream {
  /// Generates a random key for use with crypto stream.
  static Uint8List randomKey() => Sodium.cryptoStreamKeygen();

  /// Generates a random nonce for use with crypto stream.
  static Uint8List randomNonce() =>
      Sodium.randombytesBuf(Sodium.cryptoStreamNoncebytes);

  /// Generates pseudo random bytes for given nonce and secret key.
  static Uint8List stream(int clen, Uint8List nonce, Uint8List key) =>
      Sodium.cryptoStream(clen, nonce, key);

  /// Encrypts specified value using a nonce and a secret key.
  static Uint8List xor(Uint8List value, Uint8List nonce, Uint8List key) =>
      Sodium.cryptoStreamXor(value, nonce, key);

  /// Encrypts specified string value using a nonce and a secret key.
  static Uint8List xorString(String value, Uint8List nonce, Uint8List key) =>
      xor(utf8.encoder.convert(value), nonce, key);
}
