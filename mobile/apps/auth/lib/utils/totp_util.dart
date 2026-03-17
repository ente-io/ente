import 'dart:convert';
import 'package:base32/base32.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:flutter/foundation.dart';
import 'package:otp/otp.dart' as otp;
import 'package:pointycastle/api.dart' as pc;
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:steam_totp/steam_totp.dart';

int millisecondsSinceEpoch() {
  return DateTime.now().millisecondsSinceEpoch +
      PreferenceService.instance.timeOffsetInMilliSeconds();
}

String getOTP(Code code) {
  if (code.type == Type.steam || code.issuer.toLowerCase() == 'steam') {
    return _getSteamCode(code);
  }
  if (code.pin != null) {
    return _getYandexCode(code);
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

String getNextTotp(Code code) {
  if (code.type == Type.steam || code.issuer.toLowerCase() == 'steam') {
    return _getSteamCode(code, true);
  }
  if (code.pin != null) {
    return _getYandexCode(code, true);
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
  if (code.type == Type.steam || code.issuer.toLowerCase() == 'steam') {
    final SteamTOTP steamTotp = SteamTOTP(secret: code.secret);
    for (int i = 0; i < count; i++) {
      int generatedTime = startTime + code.period * 1000 * i;
      codes.add(steamTotp.generate(generatedTime ~/ 1000));
    }
  } else if (code.pin != null) {
    for (int i = 0; i < count; i++) {
      int generatedTime = startTime + code.period * 1000 * i;
      codes.add(_generateYandexCode(code, generatedTime ~/ 1000));
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

String _getYandexCode(Code code, [bool isNext = false]) {
  final int secondsSinceEpoch =
      millisecondsSinceEpoch() ~/ 1000 + (isNext ? code.period : 0);
  return _generateYandexCode(code, secondsSinceEpoch);
}

String _generateYandexCode(Code code, int secondsSinceEpoch) {
  final String pin = code.pin!;
  final Uint8List secretBytes = base32.decode(getSanitizedSecret(code.secret));
  final Uint8List pinBytes = Uint8List.fromList(utf8.encode(pin));
  final Uint8List pinWithSecret =
      Uint8List(pinBytes.length + secretBytes.length)
        ..setRange(0, pinBytes.length, pinBytes)
        ..setRange(
          pinBytes.length,
          pinBytes.length + secretBytes.length,
          secretBytes,
        );

  final Uint8List keyHash = SHA256Digest().process(pinWithSecret);
  final Uint8List key =
      keyHash.first == 0 ? Uint8List.fromList(keyHash.sublist(1)) : keyHash;
  final Uint8List digest = _hmacSha256(
    key,
    _uintToArray(secondsSinceEpoch ~/ code.period),
  );

  final int offset = digest.last & 0x0F;
  final Uint8List truncated = Uint8List.fromList(
    digest.sublist(offset, offset + 8),
  )..[0] &= 0x7F;

  int otpValue = 0;
  for (final int byte in truncated) {
    otpValue = (otpValue * 256 + byte) % 208827064576;
  }

  const String alphabet = 'abcdefghijklmnopqrstuvwxyz';
  final List<String> chars = List<String>.filled(code.digits, '');
  for (int i = code.digits - 1; i >= 0; i--) {
    chars[i] = alphabet[otpValue % alphabet.length];
    otpValue ~/= alphabet.length;
  }

  return chars.join();
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

Uint8List _hmacSha256(Uint8List key, Uint8List message) {
  final HMac hmac = HMac(SHA256Digest(), 64)..init(pc.KeyParameter(key));
  return hmac.process(message);
}

Uint8List _uintToArray(int n) {
  final Uint8List result = Uint8List(8);
  int remaining = n;
  for (int i = 7; i >= 0; i--) {
    result[i] = remaining & 0xFF;
    remaining ~/= 256;
  }
  return result;
}
