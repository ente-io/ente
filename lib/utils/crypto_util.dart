import 'package:encrypt/encrypt.dart';

class CryptoUtil {
  static String encrypt(String plainText, String key) {
    final encrypter = Encrypter(AES(Key.fromUtf8(key)));
    return encrypter.encrypt(plainText).base64;
  }

  static String decrypt(String cipherText, String key) {
    final encrypter = Encrypter(AES(Key.fromUtf8(key)));
    return encrypter.decrypt(Encrypted.fromBase64(cipherText));
  }
}
