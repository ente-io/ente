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
  static Uint8List getSecureRandomBytes({int length = 32}) {
    return SecureRandom(length).bytes;
  }

  static Uint8List scrypt(Uint8List plainText, Uint8List salt) {
    return steel.PassCrypt.scrypt()
        .hashBytes(salt: salt, input: plainText, len: 32);
  }

  static bool compareHash(Uint8List plainText, Uint8List hash, Uint8List salt) {
    return base64.encode(scrypt(plainText, salt)) == base64.encode(hash);
  }

  static Uint8List aesEncrypt(
      Uint8List plainText, Uint8List key, Uint8List iv) {
    final encrypter = AES(Key(key));
    return encrypter
        .encrypt(
          plainText,
          iv: IV(iv),
        )
        .bytes;
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
      Uint8List source, String destinationPath, String base64EncodedKey) async {
    final args = Map<String, dynamic>();
    args["key"] = base64EncodedKey;
    args["source"] = source;
    args["destination"] = destinationPath;
    return Computer().compute(runEncryptDataToFile, param: args);
  }

  static Future<String> encryptDataToData(
      Uint8List source, String base64EncodedKey) async {
    final destinationPath =
        Configuration.instance.getTempDirectory() + Uuid().v4();
    return encryptDataToFile(source, destinationPath, base64EncodedKey)
        .then((value) {
      final file = io.File(destinationPath);
      final data = file.readAsBytesSync();
      file.deleteSync();
      return base64.encode(data);
    });
  }

  static Future<void> decryptFileToFile(String sourcePath,
      String destinationPath, String base64EncodedKey) async {
    final args = Map<String, String>();
    args["key"] = base64EncodedKey;
    args["source"] = sourcePath;
    args["destination"] = destinationPath;
    return Computer().compute(runDecryptFileToFile, param: args);
  }

  static Future<Uint8List> decryptFileToData(
      String sourcePath, String base64EncodedKey) {
    final args = Map<String, String>();
    args["key"] = base64EncodedKey;
    args["source"] = sourcePath;
    return Computer().compute(runDecryptFileToData, param: args);
  }

  static Future<Uint8List> decryptDataToData(
      Uint8List source, String base64EncodedKey) {
    final sourcePath = Configuration.instance.getTempDirectory() + Uuid().v4();
    final file = io.File(sourcePath);
    file.writeAsBytesSync(source);
    return decryptFileToData(sourcePath, base64EncodedKey).then((value) {
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
