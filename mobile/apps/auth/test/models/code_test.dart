import 'dart:convert';
import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/models/code_display.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';

void main() {
  test("parseCodeFromRawData", () {
    final code1 = Code.fromOTPAuthUrl(
      "otpauth://totp/example%20finance%3Aee%40ff.gg?secret=ASKZNWOU6SVYAMVS",
    );
    expect(code1.issuer, "example finance", reason: "issuerMismatch");
    expect(code1.account, "ee@ff.gg", reason: "accountMismatch");
    expect(code1.secret, "ASKZNWOU6SVYAMVS");
  });

  test("parseDocumentedFormat", () {
    final code = Code.fromOTPAuthUrl(
      "otpauth://totp/testdata@ente.io?secret=ASKZNWOU6SVYAMVS&issuer=GitHub",
    );
    expect(code.issuer, "GitHub", reason: "issuerMismatch");
    expect(code.account, "testdata@ente.io", reason: "accountMismatch");
    expect(code.secret, "ASKZNWOU6SVYAMVS");
  });

  test("validateCount", () {
    final code = Code.fromOTPAuthUrl(
      "otpauth://hotp/testdata@ente.io?secret=ASKZNWOU6SVYAMVS&issuer=GitHub&counter=15",
    );
    expect(code.issuer, "GitHub", reason: "issuerMismatch");
    expect(code.account, "testdata@ente.io", reason: "accountMismatch");
    expect(code.secret, "ASKZNWOU6SVYAMVS");
    expect(code.counter, 15);
  });

  test("shareCodesSupport", () {
    expect(Type.totp.canShareCodes, true);
    expect(Type.steam.canShareCodes, true);
    expect(Type.yandex.canShareCodes, true);
    expect(Type.hotp.canShareCodes, false);
  });

  test("parseYandexOtp", () {
    final code = Code.fromOTPAuthUrl(
      "otpauth://yandex/test@ente.io?secret=AAAAAAAAAAAAAAAAAAAAAAAAAA&issuer=Yandex&pin=1234",
    );
    expect(code.type, Type.yandex);
    expect(code.pin, "1234");
    expect(code.digits, Code.yandexDigits);
  });

  test("parseTotpWithPinDoesNotBecomeYandex", () {
    final code = Code.fromOTPAuthUrl(
      "otpauth://totp/test@ente.io?secret=ASKZNWOU6SVYAMVS&issuer=GitHub&digits=6&period=30&pin=1234",
    );
    expect(code.type, Type.totp);
    expect(code.pin, "1234");
    expect(code.digits, 6);
    expect(code.period, 30);
  });

  test("validateDisplay", () {
    Code code = Code.fromOTPAuthUrl(
      "otpauth://hotp/testdata@ente.io?secret=ASKZNWOU6SVYAMVS&issuer=GitHub&counter=15",
    );
    expect(code.issuer, "GitHub", reason: "issuerMismatch");
    expect(code.account, "testdata@ente.io", reason: "accountMismatch");
    expect(code.secret, "ASKZNWOU6SVYAMVS");
    expect(code.counter, 15);
    code = code.copyWith(
      display: CodeDisplay(pinned: true, tags: ["tag1", "com,ma", ';;%\$']),
    );
    final dataToStore = code.toOTPAuthUrlFormat();
    final restoredCode = Code.fromOTPAuthUrl(jsonDecode(dataToStore));
    expect(restoredCode.display.pinned, true);
    expect(restoredCode.display.tags, ["tag1", "com,ma", ';;%\$']);
    final secondDataToStore = restoredCode.toOTPAuthUrlFormat();
    expect(dataToStore, secondDataToStore);
  });
  //

  test("parseWithFunnyAccountName", () {
    final code = Code.fromOTPAuthUrl(
      "otpauth://totp/Mongo Atlas:Acc !@#444?algorithm=sha1&digits=6&issuer=Mongo Atlas&period=30&secret=NI4CTTFEV4G2JFE6",
    );
    expect(code.issuer, "Mongo Atlas", reason: "issuerMismatch");
    expect(code.account, "Acc !@#444", reason: "accountMismatch");
    expect(code.secret, "NI4CTTFEV4G2JFE6");
  });

  test("parseAndUpdateInChinese", () {
    const String rubberDuckQr =
        'otpauth://totp/%E6%A9%A1%E7%9A%AE%E9%B8%AD?secret=2CWDCK4EOIN5DJDRMYUMYBBO4MKSR5AX&issuer=ente.io';
    final code = Code.fromOTPAuthUrl(rubberDuckQr);
    expect(code.account, '橡皮鸭');
    final String updatedRawCode = code
        .copyWith(account: '伍迪', issuer: '鸭子')
        .rawData;
    final updateCode = Code.fromOTPAuthUrl(updatedRawCode);
    expect(updateCode.account, '伍迪', reason: 'updated accountMismatch');
    expect(updateCode.issuer, '鸭子', reason: 'updated issuerMismatch');
  });

  test('yandexDeterministicVector', () {
    const String secret = 'Q3GXYNZ7INQOWXTVKGKYBLKDU4';
    const String pin = '2452544424551078';
    const int timestamp = 1700000000; // seconds
    const String expected = 'dkpcmema';

    // local helper functions mirroring lib/utils/totp_util.dart
    String _padBase32(String value) {
      final int padLength = (8 - (value.length % 8)) % 8;
      if (padLength == 0) return value;
      return value + ('=' * padLength);
    }

    Uint8List _decodeYandexSecret(String secret) {
      final String sanitized = secret.toUpperCase().trim().replaceAll(' ', '');
      final String padded = _padBase32(sanitized);
      final Uint8List decoded = Uint8List.fromList(base32.decode(padded));
      if (decoded.length == 26) {
        return Uint8List.sublistView(decoded, 0, 16);
      }
      if (decoded.length != 16) {
        throw FormatException('Invalid Yandex secret length: ${decoded.length} bytes');
      }
      return decoded;
    }

    Uint8List _deriveYandexKeyHash(Uint8List secret, String pin) {
      final Uint8List pinBytes = Uint8List.fromList(utf8.encode(pin));
      final Uint8List input = Uint8List(pinBytes.length + secret.length);
      input.setAll(0, pinBytes);
      input.setAll(pinBytes.length, secret);
      final Uint8List hash = SHA256Digest().process(input);
      if (hash.isNotEmpty && hash[0] == 0) {
        return Uint8List.fromList(hash.sublist(1));
      }
      return hash;
    }

    Uint8List _intToBytes(int value, int length) {
      final Uint8List bytes = Uint8List(length);
      int remaining = value;
      for (int i = length - 1; i >= 0; i--) {
        bytes[i] = remaining & 0xFF;
        remaining = remaining >> 8;
      }
      return bytes;
    }

    int _bytesToInt(Uint8List bytes) {
      int result = 0;
      for (final int b in bytes) {
        result = (result << 8) | (b & 0xFF);
      }
      return result;
    }

    String _yandexCodeForCounter(Uint8List keyHash, int counter) {
      const String alphabet = 'abcdefghijklmnopqrstuvwxyz';
      const int digits = 8;
      const int modulus = 208827064576; // 26^8
      final Uint8List msg = _intToBytes(counter, 8);
      final HMac hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(keyHash));
      final Uint8List periodHash = hmac.process(msg);
      final int offset = periodHash.last & 0x0F;
      final Uint8List truncated = Uint8List.fromList(periodHash);
      truncated[offset] = truncated[offset] & 0x7F;
      final int otp = _bytesToInt(truncated.sublist(offset, offset + 8));
      int code = otp % modulus;
      final List<String> chars = List.filled(digits, 'a');
      for (int i = digits - 1; i >= 0; i--) {
        chars[i] = alphabet[code % 26];
        code ~/= 26;
      }
      return chars.join();
    }

    final Uint8List secretBytes = _decodeYandexSecret(secret);
    final Uint8List keyHash = _deriveYandexKeyHash(secretBytes, pin);
    final int counter = (timestamp) ~/ 30;
    final String got = _yandexCodeForCounter(keyHash, counter);
    expect(got, expected);
  });
}
