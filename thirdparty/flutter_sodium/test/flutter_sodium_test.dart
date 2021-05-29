import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sodium/flutter_sodium.dart';

void main() {
  setUp(() {});

  tearDown(() {});

  group('crypto_pwhash', () {
    test('consts', () {
      expect(Sodium.cryptoPwhashAlgArgon2i13, 1);
      expect(Sodium.cryptoPwhashAlgArgon2id13, 2);
      expect(Sodium.cryptoPwhashAlgDefault, 2);
      expect(Sodium.cryptoPwhashBytesMax, 4294967295);
      expect(Sodium.cryptoPwhashBytesMin, 16);
      expect(Sodium.cryptoPwhashMemlimitInteractive, 67108864);
      expect(Sodium.cryptoPwhashMemlimitMax, 4398046510080);
      expect(Sodium.cryptoPwhashMemlimitMin, 8192);
      expect(Sodium.cryptoPwhashMemlimitModerate, 268435456);
      expect(Sodium.cryptoPwhashMemlimitSensitive, 1073741824);
      expect(Sodium.cryptoPwhashOpslimitInteractive, 2);
      expect(Sodium.cryptoPwhashOpslimitMax, 4294967295);
      expect(Sodium.cryptoPwhashOpslimitMin, 1);
      expect(Sodium.cryptoPwhashOpslimitModerate, 3);
      expect(Sodium.cryptoPwhashOpslimitSensitive, 4);
      expect(Sodium.cryptoPwhashPasswdMax, 4294967295);
      expect(Sodium.cryptoPwhashPasswdMin, 0);
      expect(Sodium.cryptoPwhashPrimitive, 'argon2i');
      expect(Sodium.cryptoPwhashSaltbytes, 16);
      expect(Sodium.cryptoPwhashStrbytes, 128);
      expect(Sodium.cryptoPwhashStrprefix, '\$argon2id\$');
    });

    test('pwhash', () {
      final outlen = 16;
      final passwd = utf8.encoder.convert('hello world');
      final salt = Sodium.hex2bin('10fb7e754a23de756aacb30f810f23df');
      final opslimit = 1;
      final memlimit = 8192;
      final alg = Sodium.cryptoPwhashAlgDefault;

      final hash =
          Sodium.cryptoPwhash(outlen, passwd, salt, opslimit, memlimit, alg);

      expect(hash, Sodium.hex2bin('5ac37aa9233b3bda0677c496ceea4bc0'));
    });
  });
}
