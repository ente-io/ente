import 'dart:convert';
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

Uint8List cryptoPwhashStr(Map<String, dynamic> args) {
  return Sodium.cryptoPwhashStr(
      args["input"], args["opsLimit"], args["memLimit"]);
}

bool cryptoPwhashStrVerify(Map<String, dynamic> args) {
  return Sodium.cryptoPwhashStrVerify(args["hash"], args["input"]) == 0;
}

EncryptionResult chachaEncryptFile(Map<String, dynamic> args) {
  final encryptionStartTime = DateTime.now().millisecondsSinceEpoch;
  final logger = Logger("ChaChaEncrypt");
  final sourceFile = io.File(args["sourceFilePath"]);
  final destinationFile = io.File(args["destinationFilePath"]);
  final sourceFileLength = sourceFile.lengthSync();
  logger.info("Encrypting file of size " + sourceFileLength.toString());

  final inputFile = sourceFile.openSync(mode: io.FileMode.read);
  final key = Sodium.cryptoSecretstreamXchacha20poly1305Keygen();
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

void chachaDecrypt(Map<String, dynamic> args) {
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

class CryptoUtil {
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
    return Computer().compute(cryptoSecretboxOpenEasy, param: args);
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

  static EncryptionResult encryptChaCha(Uint8List source, Uint8List key) {
    final initPushResult =
        Sodium.cryptoSecretstreamXchacha20poly1305InitPush(key);
    final encryptedData = Sodium.cryptoSecretstreamXchacha20poly1305Push(
        initPushResult.state,
        source,
        null,
        Sodium.cryptoSecretstreamXchacha20poly1305TagFinal);
    return EncryptionResult(
        encryptedData: encryptedData, header: initPushResult.header);
  }

  static Uint8List decryptChaCha(
      Uint8List source, Uint8List key, Uint8List header) {
    final pullState =
        Sodium.cryptoSecretstreamXchacha20poly1305InitPull(header, key);
    final pullResult =
        Sodium.cryptoSecretstreamXchacha20poly1305Pull(pullState, source, null);
    return pullResult.m;
  }

  static Future<EncryptionResult> encryptFile(
    String sourceFilePath,
    String destinationFilePath,
  ) {
    final args = Map<String, dynamic>();
    args["sourceFilePath"] = sourceFilePath;
    args["destinationFilePath"] = destinationFilePath;
    return Computer().compute(chachaEncryptFile, param: args);
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
    return Computer().compute(chachaDecrypt, param: args);
  }

  static Uint8List generateKey() {
    return Sodium.cryptoSecretboxKeygen();
  }

  static Uint8List getSaltToDeriveKey() {
    return Sodium.randombytesBuf(Sodium.cryptoPwhashSaltbytes);
  }

  static Uint8List deriveKey(Uint8List passphrase, Uint8List salt) {
    return Sodium.cryptoPwhash(
        Sodium.cryptoSecretboxKeybytes,
        passphrase,
        salt,
        Sodium.cryptoPwhashOpslimitInteractive,
        Sodium.cryptoPwhashMemlimitInteractive,
        Sodium.cryptoPwhashAlgDefault);
  }

  static Future<String> hash(Uint8List input) async {
    Sodium.init();
    final args = Map<String, dynamic>();
    args["input"] = input;
    args["opsLimit"] = Sodium.cryptoPwhashOpslimitSensitive;
    args["memLimit"] = Sodium.cryptoPwhashMemlimitModerate;
    return utf8.decode(await Computer().compute(cryptoPwhashStr, param: args));
  }

  static Future<bool> verifyHash(Uint8List input, String hash) async {
    final args = Map<String, dynamic>();
    args["input"] = input;
    args["hash"] = utf8.encode(hash);
    return await Computer().compute(cryptoPwhashStrVerify, param: args);
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
}
