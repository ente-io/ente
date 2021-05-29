import 'dart:typed_data';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'key_pair.dart';
import 'sodium.dart';

/// Computes a signature for a message using a secret key, and provides verification using a public key.
class CryptoSign {
  /// Generates a random key for use with public-key signatures.
  static KeyPair randomKeys() => Sodium.cryptoSignKeypair();

  /// Generates a random seed for use in seedKeys.
  static Uint8List randomSeed() {
    return Sodium.randombytesBuf(Sodium.cryptoSignSeedbytes);
  }

  /// Generates a secret key and a corresponding public key for given seed.
  static KeyPair seedKeys(Uint8List seed) => Sodium.cryptoSignSeedKeypair(seed);

  /// Prepends a signature to specified message for given secret key.
  static Uint8List sign(Uint8List message, Uint8List secretKey) =>
      Sodium.cryptoSign(message, secretKey);

  /// Prepends a signature to specified string message for given secret key.
  static Uint8List signString(String message, Uint8List secretKey) =>
      sign(utf8.encoder.convert(message), secretKey);

  /// Checks the signed message using given public key and returns the message with the signature removed.
  static Uint8List open(Uint8List signedMessage, Uint8List publicKey) =>
      Sodium.cryptoSignOpen(signedMessage, publicKey);

  /// Checks the signed message using given public key and returns the string message with the signature removed.
  static String openString(Uint8List signedMessage, Uint8List publicKey) {
    final m = open(signedMessage, publicKey);
    return utf8.decode(m);
  }

  /// Computes a signature for given message and secret key.
  static Uint8List signDetached(Uint8List message, Uint8List secretKey) =>
      Sodium.cryptoSignDetached(message, secretKey);

  /// Computes a signature for given string message and secret key.
  static Uint8List signStringDetached(String message, Uint8List secretKey) =>
      signDetached(utf8.encoder.convert(message), secretKey);

  /// Verifies whether the signature is valid for given message using the signer's public key.
  static bool verify(
          Uint8List signature, Uint8List message, Uint8List publicKey) =>
      Sodium.cryptoSignVerifyDetached(signature, message, publicKey) == 0;

  /// Verifies whether the signature is valid for given string message using the signer's public key.
  static bool verifyString(
          Uint8List signature, String message, Uint8List publicKey) =>
      verify(signature, utf8.encoder.convert(message), publicKey);

  /// Computes a signature for given stream and secret key.
  static Future<Uint8List> signStream(
      Stream<Uint8List> stream, Uint8List secretKey) async {
    final state = Sodium.cryptoSignInit();
    try {
      await for (var value in stream) {
        Sodium.cryptoSignUpdate(state, value);
      }
      return Sodium.cryptoSignFinalCreate(state, secretKey);
    } finally {
      calloc.free(state);
    }
  }

  /// Verifies whether the signature is valid for given stream using the signer's public key.
  static Future<bool> verifyStream(Uint8List signature,
      Stream<Uint8List> stream, Uint8List publicKey) async {
    final state = Sodium.cryptoSignInit();
    try {
      await for (var value in stream) {
        Sodium.cryptoSignUpdate(state, value);
      }
      return Sodium.cryptoSignFinalVerify(state, signature, publicKey) == 0;
    } finally {
      calloc.free(state);
    }
  }

  /// Computes a signature for given stream of strings and secret key.
  static Future<Uint8List> signStrings(
      Stream<String> stream, Uint8List secretKey) async {
    final state = Sodium.cryptoSignInit();
    try {
      await for (var value in stream) {
        Sodium.cryptoSignUpdate(state, utf8.encoder.convert(value));
      }
      return Sodium.cryptoSignFinalCreate(state, secretKey);
    } finally {
      calloc.free(state);
    }
  }

  /// Verifies whether the signature is valid for given stream using the signer's public key.
  static Future<bool> verifyStrings(
      Uint8List signature, Stream<String> stream, Uint8List publicKey) async {
    final state = Sodium.cryptoSignInit();
    try {
      await for (var value in stream) {
        Sodium.cryptoSignUpdate(state, utf8.encoder.convert(value));
      }
      return Sodium.cryptoSignFinalVerify(state, signature, publicKey) == 0;
    } finally {
      calloc.free(state);
    }
  }

  /// Extracts the seed from the secret key
  static Uint8List extractSeed(Uint8List secretKey) =>
      Sodium.cryptoSignEd25519SkToSeed(secretKey);

  /// Extracts the public key from the secret key
  static Uint8List extractPublicKey(Uint8List secretKey) =>
      Sodium.cryptoSignEd25519SkToPk(secretKey);
}
