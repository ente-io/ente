import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart';

class CryptoUtil {
  static final Random _random = Random.secure();

  static String createCryptoRandomString([int length = 32]) {
    var values = List<int>.generate(length, (i) => _random.nextInt(256));
    return base64Url.encode(values);
  }

  static String encrypt(String plainText, String key) {
    final encrypter = Encrypter(AES(Key.fromUtf8(key)));
    return encrypter.encrypt(plainText).base64;
  }

  static String decrypt(String cipherText, String key) {
    final encrypter = Encrypter(AES(Key.fromUtf8(key)));
    return encrypter.decrypt(Encrypted.fromBase64(cipherText));
  }
}
