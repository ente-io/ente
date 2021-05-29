import 'dart:typed_data';
import 'dart:convert';
import 'detached_cipher.dart';
import 'sodium.dart';

/// Encrypts a message with a key and a nonce and computes an authentication tag.
class SecretBox {
  /// Generates a random key for use with secret key encryption.
  static Uint8List randomKey() => Sodium.cryptoSecretboxKeygen();

  /// Generates a random nonce for use with secret key encryption.
  static Uint8List randomNonce() =>
      Sodium.randombytesBuf(Sodium.cryptoSecretboxNoncebytes);

  /// Encrypts a message with a key and a nonce.
  static Uint8List encrypt(Uint8List value, Uint8List nonce, Uint8List key) =>
      Sodium.cryptoSecretboxEasy(value, nonce, key);

  /// Verifies and decrypts a cipher text produced by encrypt.
  static Uint8List decrypt(
          Uint8List cipherText, Uint8List nonce, Uint8List key) =>
      Sodium.cryptoSecretboxOpenEasy(cipherText, nonce, key);

  /// Encrypts a string message with a key and a nonce.
  static Uint8List encryptString(
          String value, Uint8List nonce, Uint8List key) =>
      encrypt(utf8.encoder.convert(value), nonce, key);

  /// Verifies and decrypts a cipher text produced by encrypt.
  static String decryptString(
      Uint8List cipherText, Uint8List nonce, Uint8List key) {
    final m = decrypt(cipherText, nonce, key);
    return utf8.decode(m);
  }

  /// Encrypts a message with a key and a nonce, returning the encrypted message and authentication tag
  static DetachedCipher encryptDetached(
          Uint8List value, Uint8List nonce, Uint8List key) =>
      Sodium.cryptoSecretboxDetached(value, nonce, key);

  /// Verifies and decrypts a detached cipher text and tag.
  static Uint8List decryptDetached(
          Uint8List cipher, Uint8List mac, Uint8List nonce, Uint8List key) =>
      Sodium.cryptoSecretboxOpenDetached(cipher, mac, nonce, key);

  /// Encrypts a string message with a key and a nonce, returning the encrypted message and authentication tag
  static DetachedCipher encryptStringDetached(
          String value, Uint8List nonce, Uint8List key) =>
      encryptDetached(utf8.encoder.convert(value), nonce, key);

  /// Verifies and decrypts a detached cipher text and tag.
  static String decryptStringDetached(
      Uint8List cipher, Uint8List mac, Uint8List nonce, Uint8List key) {
    final m = decryptDetached(cipher, mac, nonce, key);
    return utf8.decode(m);
  }
}
