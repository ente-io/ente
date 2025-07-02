import "dart:convert";
import "dart:io";
import 'dart:typed_data';

import "package:computer/computer.dart";
import "package:ente_crypto/src/models/derived_key_result.dart";
import "package:ente_crypto/src/models/encryption_result.dart";
import "package:ente_crypto/src/models/errors.dart";
import "package:flutter_sodium/flutter_sodium.dart";
import "package:logging/logging.dart";

const int encryptionChunkSize = 4 * 1024 * 1024;
final int decryptionChunkSize =
    encryptionChunkSize + Sodium.cryptoSecretstreamXchacha20poly1305Abytes;
const int hashChunkSize = 4 * 1024 * 1024;
const int loginSubKeyLen = 32;
const int loginSubKeyId = 1;
const String loginSubKeyContext = "loginctx";

Uint8List cryptoSecretboxEasy(Map<String, dynamic> args) {
  return Sodium.cryptoSecretboxEasy(args["source"], args["nonce"], args["key"]);
}

Uint8List cryptoSecretboxOpenEasy(Map<String, dynamic> args) {
  return Sodium.cryptoSecretboxOpenEasy(
    args["cipher"],
    args["nonce"],
    args["key"],
  );
}

Uint8List cryptoPwHash(Map<String, dynamic> args) {
  return Sodium.cryptoPwhash(
    Sodium.cryptoSecretboxKeybytes,
    args["password"],
    args["salt"],
    args["opsLimit"],
    args["memLimit"],
    Sodium.cryptoPwhashAlgArgon2id13,
  );
}

Uint8List cryptoKdfDeriveFromKey(
  Map<String, dynamic> args,
) {
  return Sodium.cryptoKdfDeriveFromKey(
    args["subkeyLen"],
    args["subkeyId"],
    args["context"],
    args["key"],
  );
}

// Returns the hash for a given file
Future<Uint8List> cryptoGenericHash(Map<String, dynamic> args) async {
  final file = File(args["sourceFilePath"]);
  final state =
      Sodium.cryptoGenerichashInit(null, Sodium.cryptoGenerichashBytesMax);
  await for (final chunk in file.openRead()) {
    if (chunk is Uint8List) {
      Sodium.cryptoGenerichashUpdate(state, chunk);
    } else {
      Sodium.cryptoGenerichashUpdate(state, Uint8List.fromList(chunk));
    }
  }
  return Sodium.cryptoGenerichashFinal(state, Sodium.cryptoGenerichashBytesMax);
}

EncryptionResult chachaEncryptData(Map<String, dynamic> args) {
  final initPushResult =
      Sodium.cryptoSecretstreamXchacha20poly1305InitPush(args["key"]);
  final encryptedData = Sodium.cryptoSecretstreamXchacha20poly1305Push(
    initPushResult.state,
    args["source"],
    null,
    Sodium.cryptoSecretstreamXchacha20poly1305TagFinal,
  );
  return EncryptionResult(
    encryptedData: encryptedData,
    header: initPushResult.header,
  );
}

// Encrypts a given file, in chunks of encryptionChunkSize
Future<EncryptionResult> chachaEncryptFile(Map<String, dynamic> args) async {
  final encryptionStartTime = DateTime.now().millisecondsSinceEpoch;
  final logger = Logger("ChaChaEncrypt");
  final sourceFile = File(args["sourceFilePath"]);
  final destinationFile = File(args["destinationFilePath"]);
  final sourceFileLength = await sourceFile.length();
  logger.info("Encrypting file of size " + sourceFileLength.toString());

  final inputFile = sourceFile.openSync(mode: FileMode.read);
  final key = args["key"] ?? Sodium.cryptoSecretstreamXchacha20poly1305Keygen();
  final initPushResult =
      Sodium.cryptoSecretstreamXchacha20poly1305InitPush(key);
  var bytesRead = 0;
  var tag = Sodium.cryptoSecretstreamXchacha20poly1305TagMessage;
  while (tag != Sodium.cryptoSecretstreamXchacha20poly1305TagFinal) {
    var chunkSize = encryptionChunkSize;
    if (bytesRead + chunkSize >= sourceFileLength) {
      chunkSize = sourceFileLength - bytesRead;
      tag = Sodium.cryptoSecretstreamXchacha20poly1305TagFinal;
    }
    final buffer = await inputFile.read(chunkSize);
    bytesRead += chunkSize;
    final encryptedData = Sodium.cryptoSecretstreamXchacha20poly1305Push(
      initPushResult.state,
      buffer,
      null,
      tag,
    );
    await destinationFile.writeAsBytes(encryptedData, mode: FileMode.append);
  }
  await inputFile.close();

  logger.info(
    "Encryption time: " +
        (DateTime.now().millisecondsSinceEpoch - encryptionStartTime)
            .toString(),
  );

  return EncryptionResult(key: key, header: initPushResult.header);
}

Future<void> chachaDecryptFile(Map<String, dynamic> args) async {
  final logger = Logger("ChaChaDecrypt");
  final decryptionStartTime = DateTime.now().millisecondsSinceEpoch;
  final sourceFile = File(args["sourceFilePath"]);
  final destinationFile = File(args["destinationFilePath"]);
  final sourceFileLength = await sourceFile.length();
  logger.info("Decrypting file of size " + sourceFileLength.toString());

  final inputFile = sourceFile.openSync(mode: FileMode.read);
  final pullState = Sodium.cryptoSecretstreamXchacha20poly1305InitPull(
    args["header"],
    args["key"],
  );

  var bytesRead = 0;
  var tag = Sodium.cryptoSecretstreamXchacha20poly1305TagMessage;
  while (tag != Sodium.cryptoSecretstreamXchacha20poly1305TagFinal) {
    var chunkSize = decryptionChunkSize;
    if (bytesRead + chunkSize >= sourceFileLength) {
      chunkSize = sourceFileLength - bytesRead;
    }
    final buffer = await inputFile.read(chunkSize);
    bytesRead += chunkSize;
    final pullResult =
        Sodium.cryptoSecretstreamXchacha20poly1305Pull(pullState, buffer, null);
    await destinationFile.writeAsBytes(pullResult.m, mode: FileMode.append);
    tag = pullResult.tag;
  }
  inputFile.closeSync();

  logger.info(
    "ChaCha20 Decryption time: " +
        (DateTime.now().millisecondsSinceEpoch - decryptionStartTime)
            .toString(),
  );
}

Uint8List chachaDecryptData(Map<String, dynamic> args) {
  final pullState = Sodium.cryptoSecretstreamXchacha20poly1305InitPull(
    args["header"],
    args["key"],
  );
  final pullResult = Sodium.cryptoSecretstreamXchacha20poly1305Pull(
    pullState,
    args["source"],
    null,
  );
  return pullResult.m;
}

class CryptoUtil {
  // Note: workers are turned on during app startup.
  static final Computer _computer = Computer.shared();

  static init() {
    Sodium.init();
  }

  static Uint8List base642bin(
    String b64, {
    String? ignore,
    int variant = Sodium.base64VariantOriginal,
  }) {
    return Sodium.base642bin(b64, ignore: ignore, variant: variant);
  }

  static String bin2base64(
    Uint8List bin, {
    bool urlSafe = false,
  }) {
    return Sodium.bin2base64(
      bin,
      variant:
          urlSafe ? Sodium.base64VariantUrlsafe : Sodium.base64VariantOriginal,
    );
  }

  static String bin2hex(Uint8List bin) {
    return Sodium.bin2hex(bin);
  }

  static Uint8List hex2bin(String hex) {
    return Sodium.hex2bin(hex);
  }

  // Encrypts the given source, with the given key and a randomly generated
  // nonce, using XSalsa20 (w Poly1305 MAC).
  // This function runs on the same thread as the caller, so should be used only
  // for small amounts of data where thread switching can result in a degraded
  // user experience
  static EncryptionResult encryptSync(Uint8List source, Uint8List key) {
    final nonce = Sodium.randombytesBuf(Sodium.cryptoSecretboxNoncebytes);

    final args = <String, dynamic>{};
    args["source"] = source;
    args["nonce"] = nonce;
    args["key"] = key;
    final encryptedData = cryptoSecretboxEasy(args);
    return EncryptionResult(
      key: key,
      nonce: nonce,
      encryptedData: encryptedData,
    );
  }

  // Decrypts the given cipher, with the given key and nonce using XSalsa20
  // (w Poly1305 MAC).
  static Future<Uint8List> decrypt(
    Uint8List cipher,
    Uint8List key,
    Uint8List nonce,
  ) async {
    final args = <String, dynamic>{};
    args["cipher"] = cipher;
    args["nonce"] = nonce;
    args["key"] = key;
    return _computer.compute(
      cryptoSecretboxOpenEasy,
      param: args,
      taskName: "decrypt",
    );
  }

  // Decrypts the given cipher, with the given key and nonce using XSalsa20
  // (w Poly1305 MAC).
  // This function runs on the same thread as the caller, so should be used only
  // for small amounts of data where thread switching can result in a degraded
  // user experience
  static Uint8List decryptSync(
    Uint8List cipher,
    Uint8List key,
    Uint8List nonce,
  ) {
    final args = <String, dynamic>{};
    args["cipher"] = cipher;
    args["nonce"] = nonce;
    args["key"] = key;
    return cryptoSecretboxOpenEasy(args);
  }

  // Encrypts the given source, with the given key and a randomly generated
  // nonce, using XChaCha20 (w Poly1305 MAC).
  // This function runs on the isolate pool held by `_computer`.
  // TODO: Remove "ChaCha", an implementation detail from the function name
  static Future<EncryptionResult> encryptChaCha(
    Uint8List source,
    Uint8List key,
  ) async {
    final args = <String, dynamic>{};
    args["source"] = source;
    args["key"] = key;
    return _computer.compute(
      chachaEncryptData,
      param: args,
      taskName: "encryptChaCha",
    );
  }

  // Decrypts the given source, with the given key and header using XChaCha20
  // (w Poly1305 MAC).
  // TODO: Remove "ChaCha", an implementation detail from the function name
  static Future<Uint8List> decryptChaCha(
    Uint8List source,
    Uint8List key,
    Uint8List header,
  ) async {
    final args = <String, dynamic>{};
    args["source"] = source;
    args["key"] = key;
    args["header"] = header;
    return _computer.compute(
      chachaDecryptData,
      param: args,
      taskName: "decryptChaCha",
    );
  }

  // Encrypts the file at sourceFilePath, with the key (if provided) and a
  // randomly generated nonce using XChaCha20 (w Poly1305 MAC), and writes it
  // to the destinationFilePath.
  // If a key is not provided, one is generated and returned.
  static Future<EncryptionResult> encryptFile(
    String sourceFilePath,
    String destinationFilePath, {
    Uint8List? key,
  }) {
    final args = <String, dynamic>{};
    args["sourceFilePath"] = sourceFilePath;
    args["destinationFilePath"] = destinationFilePath;
    args["key"] = key;
    return _computer.compute(
      chachaEncryptFile,
      param: args,
      taskName: "encryptFile",
    );
  }

  // Decrypts the file at sourceFilePath, with the given key and header using
  // XChaCha20 (w Poly1305 MAC), and writes it to the destinationFilePath.
  static Future<void> decryptFile(
    String sourceFilePath,
    String destinationFilePath,
    Uint8List header,
    Uint8List key,
  ) {
    final args = <String, dynamic>{};
    args["sourceFilePath"] = sourceFilePath;
    args["destinationFilePath"] = destinationFilePath;
    args["header"] = header;
    args["key"] = key;
    return _computer.compute(
      chachaDecryptFile,
      param: args,
      taskName: "decryptFile",
    );
  }

  // Generates and returns a 256-bit key.
  static Uint8List generateKey() {
    return Sodium.cryptoSecretboxKeygen();
  }

  // Generates and returns a random byte buffer of length
  // crypto_pwhash_SALTBYTES (16)
  static Uint8List getSaltToDeriveKey() {
    return Sodium.randombytesBuf(Sodium.cryptoPwhashSaltbytes);
  }

  // Generates and returns a secret key and the corresponding public key.
  static Future<KeyPair> generateKeyPair() async {
    return Sodium.cryptoBoxKeypair();
  }

  // Decrypts the input using the given publicKey-secretKey pair
  static Uint8List openSealSync(
    Uint8List input,
    Uint8List publicKey,
    Uint8List secretKey,
  ) {
    return Sodium.cryptoBoxSealOpen(input, publicKey, secretKey);
  }

  // Encrypts the input using the given publicKey
  static Uint8List sealSync(Uint8List input, Uint8List publicKey) {
    return Sodium.cryptoBoxSeal(input, publicKey);
  }

  // Derives a key for a given password and salt using Argon2id, v1.3.
  // The function first attempts to derive a key with both memLimit and opsLimit
  // set to their Sensitive variants.
  // If this fails, say on a device with insufficient RAM, we retry by halving
  // the memLimit and doubling the opsLimit, while ensuring that we stay within
  // the min and max limits for both parameters.
  // At all points, we ensure that the product of these two variables (the area
  // under the graph that determines the amount of work required) is a constant.
  static Future<DerivedKeyResult> deriveSensitiveKey(
    Uint8List password,
    Uint8List salt,
  ) async {
    final logger = Logger("pwhash");
    final int desiredStrength = Sodium.cryptoPwhashMemlimitSensitive *
        Sodium.cryptoPwhashOpslimitSensitive;
    // When sensitive memLimit (1 GB) is used, on low spec device the OS might
    // kill the app with OOM. To avoid that, start with 256 MB and
    // corresponding ops limit (16).
    // This ensures that the product of these two variables
    // (the area under the graph that determines the amount of work required)
    // stays the same
    // SODIUM_CRYPTO_PWHASH_MEMLIMIT_SENSITIVE: 1073741824
    // SODIUM_CRYPTO_PWHASH_MEMLIMIT_MODERATE: 268435456
    // SODIUM_CRYPTO_PWHASH_OPSLIMIT_SENSITIVE: 4
    int memLimit = Sodium.cryptoPwhashMemlimitModerate;
    final factor = Sodium.cryptoPwhashMemlimitSensitive ~/
        Sodium.cryptoPwhashMemlimitModerate; // = 4
    int opsLimit = Sodium.cryptoPwhashOpslimitSensitive * factor; // = 16
    if (memLimit * opsLimit != desiredStrength) {
      throw UnsupportedError(
        "unexpcted values for memLimit $memLimit and opsLimit: $opsLimit",
      );
    }

    Uint8List key;
    while (memLimit >= Sodium.cryptoPwhashMemlimitMin &&
        opsLimit <= Sodium.cryptoPwhashOpslimitMax) {
      try {
        key = await deriveKey(password, salt, memLimit, opsLimit);
        return DerivedKeyResult(key, memLimit, opsLimit);
      } catch (e, s) {
        logger.warning(
          "failed to deriveKey mem: $memLimit, ops: $opsLimit",
          e,
          s,
        );
      }
      memLimit = (memLimit / 2).round();
      opsLimit = opsLimit * 2;
    }
    throw UnsupportedError("Cannot perform this operation on this device");
  }

  // Derives a key for the given password and salt, using Argon2id, v1.3
  // with memory and ops limit hardcoded to their Interactive variants
  // NOTE: This is only used while setting passwords for shared links, as an
  // extra layer of authentication (atop the access token and collection key).
  // More details @ https://ente.io/blog/building-shareable-links/
  static Future<DerivedKeyResult> deriveInteractiveKey(
    Uint8List password,
    Uint8List salt,
  ) async {
    final int memLimit = Sodium.cryptoPwhashMemlimitInteractive;
    final int opsLimit = Sodium.cryptoPwhashOpslimitInteractive;
    final key = await deriveKey(password, salt, memLimit, opsLimit);
    return DerivedKeyResult(key, memLimit, opsLimit);
  }

  // Derives a key for a given password, salt, memLimit and opsLimit using
  // Argon2id, v1.3.
  static Future<Uint8List> deriveKey(
    Uint8List password,
    Uint8List salt,
    int memLimit,
    int opsLimit,
  ) async {
    try {
      return await _computer.compute(
        cryptoPwHash,
        param: {
          "password": password,
          "salt": salt,
          "memLimit": memLimit,
          "opsLimit": opsLimit,
        },
        taskName: "deriveKey",
      );
    } catch (e, s) {
      final String errMessage = 'failed to deriveKey memLimit: $memLimit and '
          'opsLimit: $opsLimit';
      Logger("CryptoUtilDeriveKey").warning(errMessage, e, s);
      throw KeyDerivationError();
    }
  }

  // derives a Login key as subKey from the given key by applying KDF
  // (Key Derivation Function) with the `loginSubKeyId` and
  // `loginSubKeyLen` and `loginSubKeyContext` as context
  static Future<Uint8List> deriveLoginKey(
    Uint8List key,
  ) async {
    try {
      final Uint8List derivedKey = await _computer.compute(
        cryptoKdfDeriveFromKey,
        param: {
          "key": key,
          "subkeyId": loginSubKeyId,
          "subkeyLen": loginSubKeyLen,
          "context": utf8.encode(loginSubKeyContext),
        },
        taskName: "deriveLoginKey",
      );
      // return the first 16 bytes of the derived key
      return derivedKey.sublist(0, 16);
    } catch (e, s) {
      Logger("deriveLoginKey").severe("loginKeyDerivation failed", e, s);
      throw LoginKeyDerivationError();
    }
  }

  // Computes and returns the hash of the source file
  static Future<Uint8List> getHash(File source) {
    return _computer.compute(
      cryptoGenericHash,
      param: {
        "sourceFilePath": source.path,
      },
      taskName: "fileHash",
    );
  }
}
