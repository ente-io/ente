import 'dart:convert';
import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:flutter/foundation.dart';
import 'package:otp/otp.dart' as otp;
import 'package:pointycastle/export.dart' hide Algorithm;
import 'package:steam_totp/steam_totp.dart';

int millisecondsSinceEpoch() {
  return DateTime.now().millisecondsSinceEpoch +
      PreferenceService.instance.timeOffsetInMilliSeconds();
}

String getOTP(Code code) {
  if (_isYandexCode(code)) {
    return _getYandexCode(code);
  }
  if (code.type == Type.steam || code.issuer.toLowerCase() == 'steam') {
    return _getSteamCode(code);
  }
  if (code.type == Type.hotp) {
    return _getHOTPCode(code);
  }
  return otp.OTP.generateTOTPCodeString(
    getSanitizedSecret(code.secret),
    millisecondsSinceEpoch(),
    length: code.digits,
    interval: code.period,
    algorithm: _getAlgorithm(code),
    isGoogle: true,
  );
}

String _getHOTPCode(Code code) {
  return otp.OTP.generateHOTPCodeString(
    getSanitizedSecret(code.secret),
    code.counter,
    length: code.digits,
    algorithm: _getAlgorithm(code),
    isGoogle: true,
  );
}

String _getSteamCode(Code code, [bool isNext = false]) {
  final SteamTOTP steamtotp = SteamTOTP(secret: code.secret);

  return steamtotp.generate(
    millisecondsSinceEpoch() ~/ 1000 + (isNext ? code.period : 0),
  );
}

String _getYandexCode(Code code, [bool isNext = false]) {
  final String pin = _requireYandexPin(code);
  final Uint8List secret = _decodeYandexSecret(code.secret);
  final Uint8List keyHash = _deriveYandexKeyHash(secret, pin);
  final int epochSeconds =
      millisecondsSinceEpoch() ~/ 1000 + (isNext ? code.period : 0);
  final int counter = epochSeconds ~/ code.period;
  return _yandexCodeForCounter(keyHash, counter);
}

String getNextTotp(Code code) {
  if (_isYandexCode(code)) {
    return _getYandexCode(code, true);
  }
  if (code.type == Type.steam || code.issuer.toLowerCase() == 'steam') {
    return _getSteamCode(code, true);
  }
  return otp.OTP.generateTOTPCodeString(
    getSanitizedSecret(code.secret),
    millisecondsSinceEpoch() + code.period * 1000,
    length: code.digits,
    interval: code.period,
    algorithm: _getAlgorithm(code),
    isGoogle: true,
  );
}

// generateFutureTotpCodes generates future TOTP codes based on the current time.
// It returns the start time and a list of future codes.
(int, List<String>) generateFutureTotpCodes(Code code, int count) {
  final int startTime =
      ((millisecondsSinceEpoch() ~/ 1000) ~/ code.period) * code.period * 1000;
  final String secret = getSanitizedSecret(code.secret);
  final List<String> codes = [];
  if (_isYandexCode(code)) {
    final String pin = _requireYandexPin(code);
    final Uint8List secretBytes = _decodeYandexSecret(secret);
    final Uint8List keyHash = _deriveYandexKeyHash(secretBytes, pin);
    final int startCounter = (startTime ~/ 1000) ~/ code.period;
    for (int i = 0; i < count; i++) {
      codes.add(_yandexCodeForCounter(keyHash, startCounter + i));
    }
  } else if (code.type == Type.steam || code.issuer.toLowerCase() == 'steam') {
    final SteamTOTP steamTotp = SteamTOTP(secret: code.secret);
    for (int i = 0; i < count; i++) {
      int generatedTime = startTime + code.period * 1000 * i;
      codes.add(steamTotp.generate(generatedTime ~/ 1000));
    }
  } else {
    for (int i = 0; i < count; i++) {
      int generatedTime = startTime + code.period * 1000 * i;
      final genCode = otp.OTP.generateTOTPCodeString(
        secret,
        generatedTime,
        length: code.digits,
        interval: code.period,
        algorithm: _getAlgorithm(code),
        isGoogle: true,
      );
      codes.add(genCode);
    }
  }
  return (startTime, codes);
}

otp.Algorithm _getAlgorithm(Code code) {
  switch (code.algorithm) {
    case Algorithm.sha256:
      return otp.Algorithm.SHA256;
    case Algorithm.sha512:
      return otp.Algorithm.SHA512;
    default:
      return otp.Algorithm.SHA1;
  }
}

bool _isYandexCode(Code code) {
  return code.type == Type.yandex;
}

String _requireYandexPin(Code code) {
  final String pin = code.pin?.trim() ?? '';
  if (pin.isEmpty) {
    throw const FormatException('Yandex PIN is required');
  }
  return pin;
}

Uint8List _decodeYandexSecret(String secret) {
  final String sanitized = getSanitizedSecret(secret);
  final String padded = _padBase32(sanitized);
  final Uint8List decoded = Uint8List.fromList(base32.decode(padded));
  if (decoded.length == 26) {
    return Uint8List.sublistView(decoded, 0, 16);
  }
  if (decoded.length != 16) {
    throw FormatException(
      'Invalid Yandex secret length: ${decoded.length} bytes',
    );
  }
  return decoded;
}

String _padBase32(String value) {
  final int padLength = (8 - (value.length % 8)) % 8;
  if (padLength == 0) {
    return value;
  }
  return value + ('=' * padLength);
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

String _yandexCodeForCounter(Uint8List keyHash, int counter) {
  const String alphabet = 'abcdefghijklmnopqrstuvwxyz';
  const int digits = Code.yandexDigits;
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

String getSanitizedSecret(String secret) {
  return secret.toUpperCase().trim().replaceAll(' ', '');
}

String safeDecode(String value) {
  try {
    return Uri.decodeComponent(value);
  } catch (e) {
    // note: don't log the value, it might contain sensitive information
    debugPrint("Failed to decode $e");
    return value;
  }
}
