import 'dart:typed_data';

import 'package:aes_crypt/aes_crypt.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';

import 'package:worker_manager/worker_manager.dart';

class CryptoUtil {
  static String getBase64EncodedSecureRandomString({int length = 32}) {
    return SecureRandom(length).base64;
  }

  static String encryptToBase64(
      String plainText, String base64Key, String base64IV) {
    final encrypter = AES(Key.fromBase64(base64Key));
    return encrypter
        .encrypt(
          Uint8List.fromList(utf8.encode(plainText)),
          iv: IV.fromBase64(base64IV),
        )
        .base64;
  }

  static String decryptFromBase64(
      String base64CipherText, String base64Key, String base64IV) {
    final encrypter = AES(Key.fromBase64(base64Key));
    return utf8.decode(encrypter
        .decrypt(
          Encrypted.fromBase64(base64CipherText),
          iv: IV.fromBase64(base64IV),
        )
        .toList());
  }

  static Future<String> encryptFileToFile(
      String sourcePath, String destinationPath, String key) async {
    final args = Map<String, String>();
    args["key"] = key;
    args["source"] = sourcePath;
    args["destination"] = destinationPath;

    return Executor().execute(arg1: args, fun1: runEncryptFileToFile);
  }

  static Future<String> encryptDataToFile(
      Uint8List source, String destinationPath, String key) async {
    final args = Map<String, dynamic>();
    args["key"] = key;
    args["source"] = source;
    args["destination"] = destinationPath;
    return Executor().execute(arg1: args, fun1: runEncryptDataToFile);
  }

  static Future<void> decryptFileToFile(
      String sourcePath, String destinationPath, String key) async {
    final args = Map<String, String>();
    args["key"] = key;
    args["source"] = sourcePath;
    args["destination"] = destinationPath;
    return Executor().execute(arg1: args, fun1: runDecryptFileToFile);
  }

  static Future<Uint8List> decryptFileToData(String sourcePath, String key) {
    final args = Map<String, String>();
    args["key"] = key;
    args["source"] = sourcePath;
    return Executor().execute(arg1: args, fun1: runDecryptFileToData);
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
