import 'dart:typed_data';
import 'dart:convert';
import 'sodium.dart';

/// Defines the supported password hashing algorithms.
enum PasswordHashAlgorithm {
  /// The recommended algoritm.
  Default,

  /// Version 1.3 of the Argon2i algorithm.
  Argon2i13,

  /// Version 1.3 of the Argon2id algorithm.
  Argon2id13
}

/// Provides an Argon2 password hashing scheme implementation.
class PasswordHash {
  static int _alg(PasswordHashAlgorithm alg) {
    switch (alg) {
      case PasswordHashAlgorithm.Argon2i13:
        return Sodium.cryptoPwhashAlgArgon2i13;
      case PasswordHashAlgorithm.Argon2id13:
        return Sodium.cryptoPwhashAlgArgon2id13;
      default:
        return Sodium.cryptoPwhashAlgDefault;
    }
  }

  /// Generates a random salt for use in password hashing.
  static Uint8List randomSalt() =>
      Sodium.randombytesBuf(Sodium.cryptoPwhashSaltbytes);

  /// Derives a hash from given password and salt.
  static Uint8List hash(Uint8List password, Uint8List salt,
      {int? outlen,
      int? opslimit,
      int? memlimit,
      PasswordHashAlgorithm alg = PasswordHashAlgorithm.Default}) {
    outlen ??= Sodium.cryptoPwhashBytesMin;
    opslimit ??= Sodium.cryptoPwhashOpslimitInteractive;
    memlimit ??= Sodium.cryptoPwhashMemlimitInteractive;

    return Sodium.cryptoPwhash(
        outlen, password, salt, opslimit, memlimit, _alg(alg));
  }

  /// Derives a hash from given string password and salt.
  static Uint8List hashString(String password, Uint8List salt,
          {int? outlen,
          int? opslimit,
          int? memlimit,
          PasswordHashAlgorithm alg = PasswordHashAlgorithm.Default}) =>
      hash(utf8.encoder.convert(password), salt,
          outlen: outlen, opslimit: opslimit, memlimit: memlimit);

  /// Computes a password verification string for given password.
  static String hashStorage(Uint8List password,
      {int? opslimit, int? memlimit}) {
    opslimit ??= Sodium.cryptoPwhashOpslimitInteractive;
    memlimit ??= Sodium.cryptoPwhashMemlimitInteractive;

    final str = Sodium.cryptoPwhashStr(password, opslimit, memlimit);
    // ascii decode null-terminated string
    return ascii.decode(str.takeWhile((c) => c != 0).toList());
  }

  /// Computes a password verification string for given string password.
  static String hashStringStorage(String password,
          {int? opslimit, int? memlimit}) =>
      hashStorage(utf8.encoder.convert(password),
          opslimit: opslimit, memlimit: memlimit);

  /// Computes a password verification string for given password in moderate mode.
  static String hashStringStorageModerate(String password) =>
      hashStringStorage(password,
          opslimit: Sodium.cryptoPwhashOpslimitModerate,
          memlimit: Sodium.cryptoPwhashMemlimitModerate);

  /// Computes a password verification string for given password in sensitive mode.
  static String hashStringStorageSensitive(String password) =>
      hashStringStorage(password,
          opslimit: Sodium.cryptoPwhashOpslimitSensitive,
          memlimit: Sodium.cryptoPwhashMemlimitSensitive);

  /// Verifies that the storage is a valid password verification string for given password.
  static bool verifyStorage(String storage, String password) {
    final str = ascii.encode(storage);
    final passwd = utf8.encoder.convert(password);

    return Sodium.cryptoPwhashStrVerify(str, passwd) == 0;
  }
}
