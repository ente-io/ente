import 'dart:typed_data';
import 'dart:convert';
import 'detached_cipher.dart';
import 'key_pair.dart';
import 'sodium.dart';

/// Public-key authenticated encryption
class CryptoBox {
  /// Generates a random secret key and a corresponding public key.
  static KeyPair randomKeys() => Sodium.cryptoBoxKeypair();

  /// Generates a random seed for use in seedKeys.
  static Uint8List randomSeed() =>
      Sodium.randombytesBuf(Sodium.cryptoBoxSeedbytes);

  /// Generates a secret key and a corresponding public key using given seed.
  static KeyPair seedKeys(Uint8List seed) => Sodium.cryptoBoxSeedKeypair(seed);

  /// Generates a random nonce for use with public key-authenticated encryption.
  static Uint8List randomNonce() =>
      Sodium.randombytesBuf(Sodium.cryptoBoxNoncebytes);

  /// Computes a shared secret key given a public key and a secret key for use in precalculation interface.
  static Uint8List sharedSecret(Uint8List pk, Uint8List sk) =>
      Sodium.cryptoBoxBeforenm(pk, sk);

  /// Encrypts a message with a key and a nonce.
  static Uint8List encrypt(Uint8List value, Uint8List nonce,
          Uint8List publicKey, Uint8List secretKey) =>
      Sodium.cryptoBoxEasy(value, nonce, publicKey, secretKey);

  /// Verifies and decrypts a cipher text produced by encrypt.
  static Uint8List decrypt(Uint8List cipherText, Uint8List nonce,
          Uint8List publicKey, Uint8List secretKey) =>
      Sodium.cryptoBoxOpenEasy(cipherText, nonce, publicKey, secretKey);

  /// Encrypts a string message with a key and a nonce.
  static Uint8List encryptString(String value, Uint8List nonce,
          Uint8List publicKey, Uint8List secretKey) =>
      encrypt(utf8.encoder.convert(value), nonce, publicKey, secretKey);

  /// Verifies and decrypts a cipher text produced by encrypt.
  static String decryptString(Uint8List cipherText, Uint8List nonce,
      Uint8List publicKey, Uint8List secretKey) {
    final m = decrypt(cipherText, nonce, publicKey, secretKey);
    return utf8.decode(m);
  }

  /// Encrypts a message with a key and a nonce, returning the encrypted message and authentication tag
  static DetachedCipher encryptDetached(Uint8List value, Uint8List nonce,
          Uint8List publicKey, Uint8List secretKey) =>
      Sodium.cryptoBoxDetached(value, nonce, publicKey, secretKey);

  /// Verifies and decrypts a detached cipher text and tag.
  static Uint8List decryptDetached(Uint8List cipher, Uint8List mac,
          Uint8List nonce, Uint8List publicKey, Uint8List secretKey) =>
      Sodium.cryptoBoxOpenDetached(cipher, mac, nonce, publicKey, secretKey);

  /// Encrypts a string message with a key and a nonce, returning the encrypted message and authentication tag
  static DetachedCipher encryptStringDetached(String value, Uint8List nonce,
          Uint8List publicKey, Uint8List secretKey) =>
      encryptDetached(utf8.encoder.convert(value), nonce, publicKey, secretKey);

  /// Verifies and decrypts a detached cipher text and tag.
  static String decryptStringDetached(Uint8List cipher, Uint8List mac,
      Uint8List nonce, Uint8List publicKey, Uint8List secretKey) {
    final m = decryptDetached(cipher, mac, nonce, publicKey, secretKey);
    return utf8.decode(m);
  }

  /// Encrypts a message with a key and a nonce.
  static Uint8List encryptAfternm(
          Uint8List value, Uint8List nonce, Uint8List k) =>
      Sodium.cryptoBoxEasyAfternm(value, nonce, k);

  /// Verifies and decrypts a cipher text produced by encrypt.
  static Uint8List decryptAfternm(
          Uint8List cipherText, Uint8List nonce, Uint8List k) =>
      Sodium.cryptoBoxOpenEasyAfternm(cipherText, nonce, k);

  /// Encrypts a string message with a key and a nonce.
  static Uint8List encryptStringAfternm(
          String value, Uint8List nonce, Uint8List k) =>
      encryptAfternm(utf8.encoder.convert(value), nonce, k);

  /// Verifies and decrypts a cipher text produced by encrypt.
  static String decryptStringAfternm(
      Uint8List cipherText, Uint8List nonce, Uint8List k) {
    final m = decryptAfternm(cipherText, nonce, k);
    return utf8.decode(m);
  }

  /// Encrypts a message with a key and a nonce, returning the encrypted message and authentication tag
  static DetachedCipher encryptDetachedAfternm(
          Uint8List value, Uint8List nonce, Uint8List k) =>
      Sodium.cryptoBoxDetachedAfternm(value, nonce, k);

  /// Verifies and decrypts a detached cipher text and tag.
  static Uint8List decryptDetachedAfternm(
          Uint8List cipher, Uint8List mac, Uint8List nonce, Uint8List k) =>
      Sodium.cryptoBoxOpenDetachedAfternm(cipher, mac, nonce, k);

  /// Encrypts a string message with a key and a nonce, returning the encrypted message and authentication tag
  static DetachedCipher encryptStringDetachedAfternm(
          String value, Uint8List nonce, Uint8List k) =>
      encryptDetachedAfternm(utf8.encoder.convert(value), nonce, k);

  /// Verifies and decrypts a detached cipher text and tag.
  static String decryptStringDetachedAfternm(
      Uint8List cipher, Uint8List mac, Uint8List nonce, Uint8List k) {
    final m = decryptDetachedAfternm(cipher, mac, nonce, k);
    return utf8.decode(m);
  }
}
