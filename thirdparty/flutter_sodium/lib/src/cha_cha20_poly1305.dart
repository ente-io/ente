import 'dart:typed_data';
import 'dart:convert';
import 'detached_cipher.dart';
import 'sodium.dart';

/// The original ChaCha20-Poly1305 construction
class ChaCha20Poly1305 {
  /// Generates a random key for use with the ChaCha20-Poly1305 construction.
  static Uint8List randomKey() => Sodium.cryptoAeadChacha20poly1305Keygen();

  /// Generates a random nonce for use with the ChaCha20-Poly1305 construction.
  static Uint8List randomNonce() =>
      Sodium.randombytesBuf(Sodium.cryptoAeadChacha20poly1305Npubbytes);

  /// Encrypts a message with optional additional data, a key and a nonce.
  static Uint8List encrypt(Uint8List value, Uint8List nonce, Uint8List key,
          {Uint8List? additionalData}) =>
      Sodium.cryptoAeadChacha20poly1305Encrypt(
          value, additionalData, null, nonce, key);

  /// Verifies and decrypts a cipher text produced by encrypt.
  static Uint8List decrypt(Uint8List cipherText, Uint8List nonce, Uint8List key,
          {Uint8List? additionalData}) =>
      Sodium.cryptoAeadChacha20poly1305Decrypt(
          null, cipherText, additionalData, nonce, key);

  /// Encrypts a string message with optional additional data, a key and a nonce.
  static Uint8List encryptString(String value, Uint8List nonce, Uint8List key,
          {String? additionalData}) =>
      encrypt(utf8.encoder.convert(value), nonce, key,
          additionalData: additionalData != null
              ? utf8.encoder.convert(additionalData)
              : null);

  /// Verifies and decrypts a cipher text produced by encrypt.
  static String decryptString(
      Uint8List cipherText, Uint8List nonce, Uint8List key,
      {String? additionalData}) {
    final m = decrypt(cipherText, nonce, key,
        additionalData: additionalData != null
            ? utf8.encoder.convert(additionalData)
            : null);
    return utf8.decode(m);
  }

  /// Encrypts a message with optional additional data, a key and a nonce. Returns a detached cipher text and mac.
  static DetachedCipher encryptDetached(
          Uint8List value, Uint8List nonce, Uint8List key,
          {Uint8List? additionalData}) =>
      Sodium.cryptoAeadChacha20poly1305EncryptDetached(
          value, additionalData, null, nonce, key);

  /// Verifies and decrypts a cipher text and mac produced by encrypt detached.
  static Uint8List decryptDetached(
          Uint8List cipher, Uint8List mac, Uint8List nonce, Uint8List key,
          {Uint8List? additionalData}) =>
      Sodium.cryptoAeadChacha20poly1305DecryptDetached(
          null, cipher, mac, additionalData, nonce, key);

  /// Encrypts a string message with optional additional data, a key and a nonce. Returns a detached cipher text and mac.
  static DetachedCipher encryptStringDetached(
          String value, Uint8List nonce, Uint8List key,
          {String? additionalData}) =>
      encryptDetached(utf8.encoder.convert(value), nonce, key,
          additionalData: additionalData != null
              ? utf8.encoder.convert(additionalData)
              : null);

  /// Verifies and decrypts a cipher text and mac produced by encrypt detached.
  static String decryptStringDetached(
      Uint8List cipher, Uint8List mac, Uint8List nonce, Uint8List key,
      {String? additionalData}) {
    final m = decryptDetached(cipher, mac, nonce, key,
        additionalData: additionalData != null
            ? utf8.encoder.convert(additionalData)
            : null);
    return utf8.decode(m);
  }
}
