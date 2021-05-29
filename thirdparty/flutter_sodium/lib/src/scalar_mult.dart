import 'dart:typed_data';
import 'sodium.dart';

/// Performs scalar multiplication of elliptic curve points
class ScalarMult {
  /// Generates a random secret key.
  static Uint8List randomSecretKey() =>
      Sodium.randombytesBuf(Sodium.cryptoScalarmultScalarbytes);

  /// Computes a public key given specified secret key.
  static Uint8List computePublicKey(Uint8List secretKey) =>
      Sodium.cryptoScalarmultBase(secretKey);

  /// Computes a shared secret given a user's secret key and another user's public key.
  static Uint8List computeSharedSecret(
          Uint8List secretKey, Uint8List publicKey) =>
      Sodium.cryptoScalarmult(secretKey, publicKey);
}
