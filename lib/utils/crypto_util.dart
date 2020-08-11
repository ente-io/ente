import 'dart:typed_data';

import 'package:aes_crypt/aes_crypt.dart';
import 'package:encrypt/encrypt.dart';

class CryptoUtil {
  static String getBase64EncodedSecureRandomString({int length = 32}) {
    return SecureRandom(length).base64;
  }

  static String encrypt(String plainText, String base64Key, String base64IV) {
    final encrypter = Encrypter(AES(Key.fromBase64(base64Key)));
    final iv = base64IV == null ? null : IV.fromBase64(base64IV);
    return encrypter.encrypt(plainText, iv: iv).base64;
  }

  static String decrypt(String cipherText, String base64Key) {
    final encrypter = Encrypter(AES(Key.fromBase64(base64Key)));
    return encrypter.decrypt(Encrypted.fromBase64(cipherText));
  }

  static Future<void> encryptFile(String sourcePath, String destinationPath,
      String base64Key, String base64IV) async {
    final encrypter = AesCrypt("hello");
    encrypter.aesSetParams(Key.fromBase64(base64Key).bytes,
        IV.fromBase64(base64IV).bytes, AesMode.cbc);
    encrypter.setOverwriteMode(AesCryptOwMode.on);
    await encrypter.encryptFile(sourcePath, destinationPath);
  }

  static Future<void> encryptData(Uint8List source, String destinationPath,
      String base64Key, String base64IV) async {
    final encrypter = AesCrypt("hello");
    encrypter.aesSetParams(Key.fromBase64(base64Key).bytes,
        IV.fromBase64(base64IV).bytes, AesMode.cbc);
    encrypter.setOverwriteMode(AesCryptOwMode.on);
    await encrypter.encryptDataToFile(source, destinationPath);
  }
}
