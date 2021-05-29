import 'dart:typed_data';
import 'dart:convert';
import 'key_pair.dart';
import 'sodium.dart';

/// Anonymously send messages to a recipient given its public key.
class SealedBox {
  /// Generates a random secret key and a corresponding public key.
  static KeyPair randomKeys() => Sodium.cryptoBoxKeypair();

  /// Encrypts a value for a recipient having specified public key.
  static Uint8List seal(Uint8List value, Uint8List publicKey) =>
      Sodium.cryptoBoxSeal(value, publicKey);

  /// Decrypts the ciphertext using given keypair.
  static Uint8List open(Uint8List cipher, KeyPair keys) =>
      Sodium.cryptoBoxSealOpen(cipher, keys.pk, keys.sk);

  /// Encrypts a string message for a recipient having specified public key.
  static Uint8List sealString(String value, Uint8List publicKey) =>
      seal(utf8.encoder.convert(value), publicKey);

  /// Decrypts the ciphertext using given keypair.
  static String openString(Uint8List cipher, KeyPair keys) {
    final m = open(cipher, keys);
    return utf8.decode(m);
  }
}
