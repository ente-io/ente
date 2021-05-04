import 'dart:typed_data';

import 'dart:io' as io;
import 'package:computer/computer.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/encryption_result.dart';

final int encryptionChunkSize = 4 * 1024 * 1024;
final int decryptionChunkSize =
    encryptionChunkSize + Sodium.cryptoSecretstreamXchacha20poly1305Abytes;

Uint8List cryptoSecretboxEasy(Map<String, dynamic> args) {
  return Sodium.cryptoSecretboxEasy(args["source"], args["nonce"], args["key"]);
}

Uint8List cryptoSecretboxOpenEasy(Map<String, dynamic> args) {
  return Sodium.cryptoSecretboxOpenEasy(
      args["cipher"], args["nonce"], args["key"]);
}

Uint8List cryptoPwHash(Map<String, dynamic> args) {
  return Sodium.cryptoPwhash(
    Sodium.cryptoSecretboxKeybytes,
    args["password"],
    args["salt"],
    args["opsLimit"],
    args["memLimit"],
    Sodium.cryptoPwhashAlgDefault,
  );
}

EncryptionResult chachaEncryptData(Map<String, dynamic> args) {
  final initPushResult =
      Sodium.cryptoSecretstreamXchacha20poly1305InitPush(args["key"]);
  final encryptedData = Sodium.cryptoSecretstreamXchacha20poly1305Push(
      initPushResult.state,
      args["source"],
      null,
      Sodium.cryptoSecretstreamXchacha20poly1305TagFinal);
  return EncryptionResult(
      encryptedData: encryptedData, header: initPushResult.header);
}

EncryptionResult chachaEncryptFile(Map<String, dynamic> args) {
  final encryptionStartTime = DateTime.now().millisecondsSinceEpoch;
  final logger = Logger("ChaChaEncrypt");
  final sourceFile = io.File(args["sourceFilePath"]);
  final destinationFile = io.File(args["destinationFilePath"]);
  final sourceFileLength = sourceFile.lengthSync();
  logger.info("Encrypting file of size " + sourceFileLength.toString());

  final inputFile = sourceFile.openSync(mode: io.FileMode.read);
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
    final buffer = inputFile.readSync(chunkSize);
    bytesRead += chunkSize;
    final encryptedData = Sodium.cryptoSecretstreamXchacha20poly1305Push(
        initPushResult.state, buffer, null, tag);
    destinationFile.writeAsBytesSync(encryptedData, mode: io.FileMode.append);
  }
  inputFile.closeSync();

  logger.info("Encryption time: " +
      (DateTime.now().millisecondsSinceEpoch - encryptionStartTime).toString());

  return EncryptionResult(key: key, header: initPushResult.header);
}

void chachaDecryptFile(Map<String, dynamic> args) {
  final logger = Logger("ChaChaDecrypt");
  final decryptionStartTime = DateTime.now().millisecondsSinceEpoch;
  final sourceFile = io.File(args["sourceFilePath"]);
  final destinationFile = io.File(args["destinationFilePath"]);
  final sourceFileLength = sourceFile.lengthSync();
  logger.info("Decrypting file of size " + sourceFileLength.toString());

  final inputFile = sourceFile.openSync(mode: io.FileMode.read);
  final pullState = Sodium.cryptoSecretstreamXchacha20poly1305InitPull(
      args["header"], args["key"]);

  var bytesRead = 0;
  var tag = Sodium.cryptoSecretstreamXchacha20poly1305TagMessage;
  while (tag != Sodium.cryptoSecretstreamXchacha20poly1305TagFinal) {
    var chunkSize = decryptionChunkSize;
    if (bytesRead + chunkSize >= sourceFileLength) {
      chunkSize = sourceFileLength - bytesRead;
    }
    final buffer = inputFile.readSync(chunkSize);
    bytesRead += chunkSize;
    final pullResult =
        Sodium.cryptoSecretstreamXchacha20poly1305Pull(pullState, buffer, null);
    destinationFile.writeAsBytesSync(pullResult.m, mode: io.FileMode.append);
    tag = pullResult.tag;
  }
  inputFile.closeSync();

  logger.info("ChaCha20 Decryption time: " +
      (DateTime.now().millisecondsSinceEpoch - decryptionStartTime).toString());
}

Uint8List chachaDecryptData(Map<String, dynamic> args) {
  final pullState =
      Sodium.cryptoSecretstreamXchacha20poly1305InitPull(args["header"], args["key"]);
  final pullResult =
      Sodium.cryptoSecretstreamXchacha20poly1305Pull(pullState, args["source"], null);
  return pullResult.m;
}

class CryptoUtil {
  static Computer _computer = Computer();

  static init() {
    _computer.turnOn(workersCount: 4);
    Sodium.init();
  }

  static EncryptionResult encryptSync(Uint8List source, Uint8List key) {
    final nonce = Sodium.randombytesBuf(Sodium.cryptoSecretboxNoncebytes);

    final args = Map<String, dynamic>();
    args["source"] = source;
    args["nonce"] = nonce;
    args["key"] = key;
    final encryptedData = cryptoSecretboxEasy(args);
    return EncryptionResult(
        key: key, nonce: nonce, encryptedData: encryptedData);
  }

  static Future<Uint8List> decrypt(
    Uint8List cipher,
    Uint8List key,
    Uint8List nonce,
  ) async {
    final args = Map<String, dynamic>();
    args["cipher"] = cipher;
    args["nonce"] = nonce;
    args["key"] = key;
    return _computer.compute(cryptoSecretboxOpenEasy, param: args);
  }

  static Uint8List decryptSync(
    Uint8List cipher,
    Uint8List key,
    Uint8List nonce,
  ) {
    final args = Map<String, dynamic>();
    args["cipher"] = cipher;
    args["nonce"] = nonce;
    args["key"] = key;
    return cryptoSecretboxOpenEasy(args);
  }

  static Future<EncryptionResult> encryptChaCha(
      Uint8List source, Uint8List key) async {
    final args = Map<String, dynamic>();
    args["source"] = source;
    args["key"] = key;
    return _computer.compute(chachaEncryptData, param: args);
  }

  static Future<Uint8List> decryptChaCha(
      Uint8List source, Uint8List key, Uint8List header) async {
    final args = Map<String, dynamic>();
    args["source"] = source;
    args["key"] = key;
    args["header"] = header;
    return _computer.compute(chachaDecryptData, param: args);
  }

  static Future<EncryptionResult> encryptFile(
    String sourceFilePath,
    String destinationFilePath, {
    Uint8List key,
  }) {
    final args = Map<String, dynamic>();
    args["sourceFilePath"] = sourceFilePath;
    args["destinationFilePath"] = destinationFilePath;
    args["key"] = key;
    return _computer.compute(chachaEncryptFile, param: args);
  }

  static Future<void> decryptFile(
    String sourceFilePath,
    String destinationFilePath,
    Uint8List header,
    Uint8List key,
  ) {
    final args = Map<String, dynamic>();
    args["sourceFilePath"] = sourceFilePath;
    args["destinationFilePath"] = destinationFilePath;
    args["header"] = header;
    args["key"] = key;
    return _computer.compute(chachaDecryptFile, param: args);
  }

  static Uint8List generateKey() {
    return Sodium.cryptoSecretboxKeygen();
  }

  static Uint8List getSaltToDeriveKey() {
    return Sodium.randombytesBuf(Sodium.cryptoPwhashSaltbytes);
  }

  static Future<KeyPair> generateKeyPair() async {
    return Sodium.cryptoBoxKeypair();
  }

  static Uint8List openSealSync(
      Uint8List input, Uint8List publicKey, Uint8List secretKey) {
    return Sodium.cryptoBoxSealOpen(input, publicKey, secretKey);
  }

  static Uint8List sealSync(Uint8List input, Uint8List publicKey) {
    return Sodium.cryptoBoxSeal(input, publicKey);
  }

  static Future<DerivedKeyResult> deriveSensitiveKey(
      Uint8List password, Uint8List salt) async {
    final logger = Logger("pwhash");
    int memLimit = Sodium.cryptoPwhashMemlimitSensitive;
    int opsLimit = Sodium.cryptoPwhashOpslimitSensitive;
    Uint8List key;
    while (memLimit > Sodium.cryptoPwhashMemlimitMin &&
        opsLimit < Sodium.cryptoPwhashOpslimitMax) {
      try {
        key = await deriveKey(password, salt, memLimit, opsLimit);
        return DerivedKeyResult(key, memLimit, opsLimit);
      } catch (e, s) {
        logger.severe(e, s);
      }
      memLimit = (memLimit / 2).round();
      opsLimit = opsLimit * 2;
    }
    throw UnsupportedError("Cannot perform this operation on this device");
  }

  static Future<Uint8List> deriveKey(
    Uint8List password,
    Uint8List salt,
    int memLimit,
    int opsLimit,
  ) {
    return _computer.compute(cryptoPwHash, param: {
      "password": password,
      "salt": salt,
      "memLimit": memLimit,
      "opsLimit": opsLimit,
    });
  }
}

class DerivedKeyResult {
  final Uint8List key;
  final int memLimit;
  final int opsLimit;

  DerivedKeyResult(this.key, this.memLimit, this.opsLimit);
}
