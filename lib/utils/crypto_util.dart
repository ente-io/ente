import 'dart:developer';
import 'dart:typed_data';

import 'package:aes_crypt/aes_crypt.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';

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

  static Future<void> encryptFileToFile(
      String sourcePath, String destinationPath, String key) async {
    final encrypter = getEncrypter(key);
    await encrypter.encryptFile(sourcePath, destinationPath);
  }

  static Future<void> encryptDataToFile(
      Uint8List source, String destinationPath, String key) async {
    final encrypter = getEncrypter(key);
    await encrypter.encryptDataToFile(source, destinationPath);
  }

  static Future<void> decryptFileToFile(
      String sourcePath, String destinationPath, String key) async {
    final encrypter = getEncrypter(key);
    await encrypter.decryptFile(sourcePath, destinationPath);
  }

  static Future<Uint8List> decryptFileToData(String sourcePath, String key) {
    final encrypter = getEncrypter(key);
    return encrypter.decryptDataFromFile(sourcePath);
  }

  static AesCrypt getEncrypter(String key) {
    final encrypter = AesCrypt(key);
    encrypter.aesSetMode(AesMode.cbc);
    encrypter.setOverwriteMode(AesCryptOwMode.on);
    return encrypter;
  }
}
