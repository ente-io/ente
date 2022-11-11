import 'package:ente_auth/models/code.dart';
import 'package:otp/otp.dart' as otp;

String getTotp(Code code) {
  return otp.OTP.generateTOTPCodeString(
    getSanitizedSecret(code.secret),
    DateTime.now().millisecondsSinceEpoch,
    length: code.digits,
    interval: code.period,
    algorithm: _getAlgorithm(code),
    isGoogle: true,
  );
}

String getNextTotp(Code code) {
  return otp.OTP.generateTOTPCodeString(
    getSanitizedSecret(code.secret),
    DateTime.now().millisecondsSinceEpoch + code.period * 1000,
    length: code.digits,
    interval: code.period,
    algorithm: _getAlgorithm(code),
    isGoogle: true,
  );
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
  return secret.toUpperCase().trim();
}
