import 'dart:typed_data';

import 'dart:io' as io;
import 'package:aes_crypt/aes_crypt.dart';
import 'package:computer/computer.dart';
import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt.dart' as e;
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';

import 'package:photos/core/configuration.dart';
import 'package:photos/models/encrypted_data_attributes.dart';
import 'package:photos/models/encrypted_file_attributes.dart';
import 'package:photos/models/encryption_attribute.dart';
import 'package:steel_crypt/steel_crypt.dart' as steel;
import 'package:uuid/uuid.dart';

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
    final encryptedData = await Computer().compute(chachaDecrypt, param: args);

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
      return Computer().compute(chachaDecrypt, param: args);
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
    return Computer().compute(chachaDecrypt, param: args);
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
    return SecureRandom(length).bytes;
  }

  static String getSecureRandomString({int length = 32}) {
    return SecureRandom(length).base64;
  }

  static Uint8List scrypt(Uint8List plainText, Uint8List salt) {
    return steel.PassCryptRaw.scrypt()
        .hash(salt: salt, plain: plainText, len: 32);
  }

  static Uint8List aesEncrypt(
      Uint8List plainText, Uint8List key, Uint8List iv) {
    final encrypter = AES(e.Key(key), mode: AESMode.cbc);
    return encrypter
        .encrypt(
          plainText,
          iv: IV(iv),
        )
        .bytes;
  }

  static Uint8List aesDecrypt(
      Uint8List cipherText, Uint8List key, Uint8List iv) {
    final encrypter = AES(e.Key(key), mode: AESMode.cbc);
    return encrypter.decrypt(
      Encrypted(cipherText),
      iv: IV(iv),
    );
  }

  static Future<String> encryptFileToFile(
      String sourcePath, String destinationPath, String password) async {
    final args = Map<String, dynamic>();
    args["password"] = password;
    args["source"] = sourcePath;
    args["destination"] = destinationPath;
    return Computer().compute(runEncryptFileToFile, param: args);
  }

  static Future<String> encryptDataToFile(
      Uint8List source, String destinationPath, String password) async {
    final args = Map<String, dynamic>();
    args["password"] = password;
    args["source"] = source;
    args["destination"] = destinationPath;
    return Computer().compute(runEncryptDataToFile, param: args);
  }

  static Future<Uint8List> encryptDataToData(
      Uint8List source, String password) async {
    final destinationPath =
        Configuration.instance.getTempDirectory() + Uuid().v4();
    return encryptDataToFile(source, destinationPath, password).then((value) {
      final file = io.File(destinationPath);
      final data = file.readAsBytesSync();
      file.deleteSync();
      return data;
    });
  }

  static Future<void> decryptFileToFile(
      String sourcePath, String destinationPath, String password) async {
    final args = Map<String, dynamic>();
    args["password"] = password;
    args["source"] = sourcePath;
    args["destination"] = destinationPath;
    return Computer().compute(runDecryptFileToFile, param: args);
  }

  static Future<Uint8List> decryptFileToData(
      String sourcePath, String password) {
    final args = Map<String, dynamic>();
    args["password"] = password;
    args["source"] = sourcePath;
    return Computer().compute(runDecryptFileToData, param: args);
  }

  static Future<Uint8List> decryptDataToData(
      Uint8List source, String password) {
    final sourcePath = Configuration.instance.getTempDirectory() + Uuid().v4();
    final file = io.File(sourcePath);
    file.writeAsBytesSync(source);
    return decryptFileToData(sourcePath, password).then((value) {
      file.deleteSync();
      return value;
    });
  }
}

Future<String> runEncryptFileToFile(Map<String, dynamic> args) {
  final encrypter = getEncrypter(args["password"]);
  return encrypter.encryptFile(args["source"], args["destination"]);
}

Future<String> runEncryptDataToFile(Map<String, dynamic> args) {
  final encrypter = getEncrypter(args["password"]);
  return encrypter.encryptDataToFile(args["source"], args["destination"]);
}

Future<String> runDecryptFileToFile(Map<String, dynamic> args) async {
  final encrypter = getEncrypter(args["password"]);
  return encrypter.decryptFile(args["source"], args["destination"]);
}

Future<Uint8List> runDecryptFileToData(Map<String, dynamic> args) async {
  final encrypter = getEncrypter(args["password"]);
  return encrypter.decryptDataFromFile(args["source"]);
}

AesCrypt getEncrypter(String password) {
  final encrypter = AesCrypt(password);
  encrypter.aesSetMode(AesMode.cbc);
  encrypter.setOverwriteMode(AesCryptOwMode.on);
  return encrypter;
}
