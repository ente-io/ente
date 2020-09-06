import 'dart:typed_data';

import 'dart:io' as io;
import 'package:aes_crypt/aes_crypt.dart';
import 'package:computer/computer.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';

import 'package:photos/core/configuration.dart';
import 'package:steel_crypt/steel_crypt.dart' as steel;
import 'package:uuid/uuid.dart';

class CryptoUtil {
  static String getBase64EncodedSecureRandomString({int length = 32}) {
    return SecureRandom(length).base64;
  }

  static String scrypt(String passphrase, String salt, int length) {
    return steel.PassCrypt.scrypt()
        .hash(salt: salt, inp: passphrase, len: length);
  }

  static bool compareHash(String plainText, String hash, String salt) {
    return steel.PassCrypt.scrypt()
        .check(plain: plainText, hashed: hash, salt: salt);
  }

  static String encryptToBase64(
      String plainText, String base64Key, String base64IV) {
    final encrypter = AES(Key.fromBase64(base64Key));
    return encrypter
        .encrypt(
          utf8.encode(plainText),
          iv: IV.fromBase64(base64IV),
        )
        .base64;
  }

  static String decryptFromBase64(
      String base64CipherText, String base64Key, String base64IV) {
    final encrypter = AES(Key.fromBase64(base64Key));
    return utf8.decode(encrypter.decrypt(
      Encrypted.fromBase64(base64CipherText),
      iv: IV.fromBase64(base64IV),
    ));
  }

  static Future<String> encryptFileToFile(
      String sourcePath, String destinationPath, String key) async {
    final args = Map<String, String>();
    args["key"] = key;
    args["source"] = sourcePath;
    args["destination"] = destinationPath;
    return Computer().compute(runEncryptFileToFile, param: args);
  }

  static Future<String> encryptDataToFile(
      Uint8List source, String destinationPath, String key) async {
    final args = Map<String, dynamic>();
    args["key"] = key;
    args["source"] = source;
    args["destination"] = destinationPath;
    return Computer().compute(runEncryptDataToFile, param: args);
  }

  static Future<String> encryptDataToData(Uint8List source, String key) async {
    final destinationPath =
        Configuration.instance.getTempDirectory() + Uuid().v4();
    return encryptDataToFile(source, destinationPath, key).then((value) {
      final file = io.File(destinationPath);
      final data = file.readAsBytesSync();
      file.deleteSync();
      return base64.encode(data);
    });
  }

  static Future<void> decryptFileToFile(
      String sourcePath, String destinationPath, String key) async {
    final args = Map<String, String>();
    args["key"] = key;
    args["source"] = sourcePath;
    args["destination"] = destinationPath;
    return Computer().compute(runDecryptFileToFile, param: args);
  }

  static Future<Uint8List> decryptFileToData(String sourcePath, String key) {
    final args = Map<String, String>();
    args["key"] = key;
    args["source"] = sourcePath;
    return Computer().compute(runDecryptFileToData, param: args);
  }

  static Future<Uint8List> decryptDataToData(String source, String key) {
    final sourcePath = Configuration.instance.getTempDirectory() + Uuid().v4();
    final file = io.File(sourcePath);
    file.writeAsBytesSync(base64.decode(source));
    return decryptFileToData(sourcePath, key).then((value) {
      file.deleteSync();
      return value;
    });
  }
}

Future<String> runEncryptFileToFile(Map<String, String> args) {
  final encrypter = getEncrypter(args["key"]);
  return encrypter.encryptFile(args["source"], args["destination"]);
}

Future<String> runEncryptDataToFile(Map<String, dynamic> args) {
  final encrypter = getEncrypter(args["key"]);
  return encrypter.encryptDataToFile(args["source"], args["destination"]);
}

Future<String> runDecryptFileToFile(Map<String, dynamic> args) async {
  final encrypter = getEncrypter(args["key"]);
  return encrypter.decryptFile(args["source"], args["destination"]);
}

Future<Uint8List> runDecryptFileToData(Map<String, dynamic> args) async {
  final encrypter = getEncrypter(args["key"]);
  return encrypter.decryptDataFromFile(args["source"]);
}

AesCrypt getEncrypter(String key) {
  final encrypter = AesCrypt(key);
  encrypter.aesSetMode(AesMode.cbc);
  encrypter.setOverwriteMode(AesCryptOwMode.on);
  return encrypter;
}
