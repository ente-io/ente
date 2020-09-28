import 'dart:typed_data';

import 'dart:io' as io;
import 'package:computer/computer.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';

import 'package:photos/models/encrypted_data_attributes.dart';
import 'package:photos/models/encrypted_file_attributes.dart';
import 'package:photos/models/encryption_attribute.dart';

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

ChaChaAttributes chachaEncrypt(Map<String, dynamic> args) {
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

  return ChaChaAttributes(EncryptionAttribute(bytes: key),
      EncryptionAttribute(bytes: initPushResult.header));
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
  static Future<EncryptedData> encrypt(Uint8List source,
      {Uint8List key}) async {
    if (key == null) {
      key = Sodium.cryptoSecretboxKeygen();
    }
    final nonce = Sodium.randombytesBuf(Sodium.cryptoSecretboxNoncebytes);

    final args = Map<String, dynamic>();
    args["source"] = source;
    args["nonce"] = nonce;
    args["key"] = key;
    final encryptedData =
        await Computer().compute(cryptoSecretboxEasy, param: args);

    return EncryptedData(
        EncryptionAttribute(bytes: key),
        EncryptionAttribute(bytes: nonce),
        EncryptionAttribute(bytes: encryptedData));
  }

  static Future<Uint8List> decrypt(
      Uint8List cipher, Uint8List key, Uint8List nonce,
      {bool background = false}) async {
    final args = Map<String, dynamic>();
    args["cipher"] = cipher;
    args["nonce"] = nonce;
    args["key"] = key;
    if (background) {
      return Computer().compute(cryptoSecretboxOpenEasy, param: args);
    } else {
      return cryptoSecretboxOpenEasy(args);
    }
  }

  static Future<ChaChaAttributes> encryptFile(
    String sourceFilePath,
    String destinationFilePath,
  ) {
    final args = Map<String, dynamic>();
    args["sourceFilePath"] = sourceFilePath;
    args["destinationFilePath"] = destinationFilePath;
    return Computer().compute(chachaEncrypt, param: args);
  }

  static Future<void> decryptFile(
    String sourceFilePath,
    String destinationFilePath,
    ChaChaAttributes attributes,
  ) {
    final args = Map<String, dynamic>();
    args["sourceFilePath"] = sourceFilePath;
    args["destinationFilePath"] = destinationFilePath;
    args["header"] = attributes.header.bytes;
    args["key"] = attributes.key.bytes;
    return Computer().compute(chachaDecrypt, param: args);
  }

  static Uint8List getSecureRandomBytes({int length = 32}) {
    return Sodium.randombytesBuf(length);
  }

  static Uint8List generateMasterKey() {
    return Sodium.cryptoKdfKeygen();
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

  static Future<String> hash(Uint8List passphrase) async {
    return Sodium.cryptoPwhashStr(
        passphrase,
        Sodium.cryptoPwhashOpslimitSensitive,
        Sodium.cryptoPwhashMemlimitSensitive);
  }

  static bool verifyHash(Uint8List passphrase, String hash) {
    return Sodium.cryptoPwhashStrVerify(hash, passphrase) == 0;
  }
}
