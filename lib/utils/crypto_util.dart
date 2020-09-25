import 'dart:typed_data';

import 'dart:io' as io;
import 'package:aes_crypt/aes_crypt.dart';
import 'package:computer/computer.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';

import 'package:photos/core/configuration.dart';
import 'package:photos/models/encrypted_file_attributes.dart';
import 'package:steel_crypt/steel_crypt.dart' as steel;
import 'package:uuid/uuid.dart';

class CryptoUtil {
  static Logger _logger = Logger("CryptoUtil");

  static int encryptionBlockSize = 4 * 1024 * 1024;
  static int decryptionBlockSize =
      encryptionBlockSize + Sodium.cryptoSecretstreamXchacha20poly1305Abytes;

  static Future<EncryptedFileAttributes> chachaEncrypt(
    io.File sourceFile,
    io.File destinationFile,
  ) async {
    var encryptionStartTime = DateTime.now().millisecondsSinceEpoch;

    final sourceFileLength = sourceFile.lengthSync();
    _logger.info("Encrypting file of size " + sourceFileLength.toString());

    final inputFile = await (sourceFile.open(mode: io.FileMode.read));
    final outputFile =
        await (destinationFile.open(mode: io.FileMode.writeOnlyAppend));

    final key = Sodium.cryptoSecretstreamXchacha20poly1305Keygen();
    final initPushResult =
        Sodium.cryptoSecretstreamXchacha20poly1305InitPush(key);

    var bytesRead = 0;
    var encryptionTag = Sodium.cryptoSecretstreamXchacha20poly1305TagMessage;
    while (
        encryptionTag != Sodium.cryptoSecretstreamXchacha20poly1305TagFinal) {
      bool isLastBlock = false;
      var blockLength = encryptionBlockSize;
      if (bytesRead + blockLength >= sourceFileLength) {
        blockLength = sourceFileLength - bytesRead;
        isLastBlock = true;
      }
      final blockData = await inputFile.read(blockLength);
      bytesRead += blockLength;
      if (isLastBlock) {
        encryptionTag = Sodium.cryptoSecretstreamXchacha20poly1305TagFinal;
      }
      final encryptedData = Sodium.cryptoSecretstreamXchacha20poly1305Push(
          initPushResult.state, blockData, null, encryptionTag);
      outputFile.writeFromSync(encryptedData);
    }
    await inputFile.close();
    await outputFile.close();

    _logger.info("ChaCha20 Encryption time: " +
        (DateTime.now().millisecondsSinceEpoch - encryptionStartTime)
            .toString());

    return EncryptedFileAttributes(key, initPushResult.header);
  }

  static Future<void> chachaDecrypt(
    io.File sourceFile,
    io.File destinationFile,
    EncryptedFileAttributes attributes,
  ) async {
    var decryptionStartTime = DateTime.now().millisecondsSinceEpoch;

    final sourceFileLength = sourceFile.lengthSync();
    _logger.info("Decrypting file of size " + sourceFileLength.toString());

    final inputFile = await (sourceFile.open(mode: io.FileMode.read));
    final outputFile =
        await (destinationFile.open(mode: io.FileMode.writeOnlyAppend));
    final pullState = Sodium.cryptoSecretstreamXchacha20poly1305InitPull(
        attributes.header, attributes.key);

    var bytesRead = 0;
    var tag = Sodium.cryptoSecretstreamXchacha20poly1305TagMessage;
    while (tag != Sodium.cryptoSecretstreamXchacha20poly1305TagFinal) {
      var blockLength = decryptionBlockSize;
      if (bytesRead + blockLength >= sourceFileLength) {
        blockLength = sourceFileLength - bytesRead;
      }
      final blockData = await inputFile.read(blockLength);
      bytesRead += blockLength;
      final pullResult = Sodium.cryptoSecretstreamXchacha20poly1305Pull(
          pullState, blockData, null);
      outputFile.writeFromSync(pullResult.m);
      tag = pullResult.tag;
    }
    await inputFile.close();
    await outputFile.close();

    _logger.info("ChaCha20 Decryption time: " +
        (DateTime.now().millisecondsSinceEpoch - decryptionStartTime)
            .toString());
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
    final encrypter = AES(Key(key), mode: AESMode.cbc);
    return encrypter
        .encrypt(
          plainText,
          iv: IV(iv),
        )
        .bytes;
  }

  static Uint8List aesDecrypt(
      Uint8List cipherText, Uint8List key, Uint8List iv) {
    final encrypter = AES(Key(key), mode: AESMode.cbc);
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
