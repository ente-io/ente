class Code {
  static const defaultDigits = 6;
  static const defaultPeriod = 30;

  int? id;
  final String account;
  final String issuer;
  final int digits;
  final int period;
  final String secret;
  final Algorithm algorithm;
  final Type type;
  final String rawData;

  Code(
    this.account,
    this.issuer,
    this.digits,
    this.period,
    this.secret,
    this.algorithm,
    this.type,
    this.rawData, {
    this.id,
  });

  static Code fromAccountAndSecret(String account, String secret) {
    return Code(
      account,
      "",
      defaultDigits,
      defaultPeriod,
      secret,
      Algorithm.sha1,
      Type.totp,
      "otpauth://totp/" +
          account +
          ":" +
          account +
          "?algorithm=SHA1&digits=6&issuer=" +
          account +
          "period=30&secret=" +
          secret,
    );
  }

  static Code fromRawData(String rawData) {
    Uri uri = Uri.parse(rawData);
    return Code(
      _getAccount(uri),
      _getIssuer(uri),
      _getDigits(uri),
      _getPeriod(uri),
      uri.queryParameters['secret']!,
      _getAlgorithm(uri),
      _getType(uri),
      rawData,
    );
  }

  static String _getAccount(Uri uri) {
    try {
      return uri.path.split(':')[1];
    } catch (e) {
      return "";
    }
  }

  static String _getIssuer(Uri uri) {
    try {
      return uri.path.split(':')[0].substring(1);
    } catch (e) {
      return "";
    }
  }

  static int _getDigits(Uri uri) {
    try {
      return int.parse(uri.queryParameters['digits']!);
    } catch (e) {
      return defaultDigits;
    }
  }

  static int _getPeriod(Uri uri) {
    try {
      return int.parse(uri.queryParameters['period']!);
    } catch (e) {
      return defaultPeriod;
    }
  }

  static Algorithm _getAlgorithm(Uri uri) {
    try {
      final algorithm =
          uri.queryParameters['algorithm'].toString().toLowerCase();
      if (algorithm == "sha256") {
        return Algorithm.sha256;
      } else if (algorithm == "sha512") {
        return Algorithm.sha512;
      }
    } catch (e) {
      // nothing
    }
    return Algorithm.sha1;
  }

  static Type _getType(Uri uri) {
    return uri.host == "totp" ? Type.totp : Type.hotp;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Code &&
        other.account == account &&
        other.issuer == issuer &&
        other.digits == digits &&
        other.period == period &&
        other.secret == secret &&
        other.type == type &&
        other.rawData == rawData;
  }

  @override
  int get hashCode {
    return account.hashCode ^
        issuer.hashCode ^
        digits.hashCode ^
        period.hashCode ^
        secret.hashCode ^
        type.hashCode ^
        rawData.hashCode;
  }
}

enum Type {
  totp,
  hotp,
}

enum Algorithm {
  sha1,
  sha256,
  sha512,
}
