import 'package:ente_auth/models/code_display.dart';
import 'package:ente_auth/utils/totp_util.dart';
import 'package:flutter/foundation.dart';

class Code {
  static const defaultDigits = 6;
  static const defaultPeriod = 30;

  int? generatedID;
  final String account;
  final String issuer;
  final int digits;
  final int period;
  final String secret;
  final Algorithm algorithm;
  final Type type;

  /// otpauth url in the code
  final String rawData;
  final int counter;
  bool? hasSynced;

  final CodeDisplay? display;

  bool get isPinned => display?.pinned ?? false;

  Code(
    this.account,
    this.issuer,
    this.digits,
    this.period,
    this.secret,
    this.algorithm,
    this.type,
    this.counter,
    this.rawData, {
    this.generatedID,
    this.display,
  });

  Code copyWith({
    String? account,
    String? issuer,
    int? digits,
    int? period,
    String? secret,
    Algorithm? algorithm,
    Type? type,
    int? counter,
    CodeDisplay? display,
  }) {
    final String updateAccount = account ?? this.account;
    final String updateIssuer = issuer ?? this.issuer;
    final int updatedDigits = digits ?? this.digits;
    final int updatePeriod = period ?? this.period;
    final String updatedSecret = secret ?? this.secret;
    final Algorithm updatedAlgo = algorithm ?? this.algorithm;
    final Type updatedType = type ?? this.type;
    final int updatedCounter = counter ?? this.counter;
    final CodeDisplay? updatedDisplay = display ?? this.display;

    return Code(
      updateAccount,
      updateIssuer,
      updatedDigits,
      updatePeriod,
      updatedSecret,
      updatedAlgo,
      updatedType,
      updatedCounter,
      "otpauth://${updatedType.name}/$updateIssuer:$updateAccount?algorithm=${updatedAlgo.name}&digits=$updatedDigits&issuer=$updateIssuer&period=$updatePeriod&secret=$updatedSecret${updatedType == Type.hotp ? "&counter=$updatedCounter" : ""}",
      generatedID: generatedID,
      display: updatedDisplay,
    );
  }

  static Code fromAccountAndSecret(
    String account,
    String issuer,
    String secret,
  ) {
    return Code(
      account,
      issuer,
      defaultDigits,
      defaultPeriod,
      secret,
      Algorithm.sha1,
      Type.totp,
      0,
      "otpauth://totp/$issuer:$account?algorithm=SHA1&digits=6&issuer=$issuer&period=30&secret=$secret",
    );
  }

  static Code fromOTPAuthUrl(String rawData, {CodeDisplay? display}) {
    Uri uri = Uri.parse(rawData);
    try {
      return Code(
        _getAccount(uri),
        _getIssuer(uri),
        _getDigits(uri),
        _getPeriod(uri),
        getSanitizedSecret(uri.queryParameters['secret']!),
        _getAlgorithm(uri),
        _getType(uri),
        _getCounter(uri),
        rawData,
        display: display,
      );
    } catch (e) {
      // if account name contains # without encoding,
      // rest of the url are treated as url fragment
      if (rawData.contains("#")) {
        return Code.fromOTPAuthUrl(rawData.replaceAll("#", '%23'));
      } else {
        rethrow;
      }
    }
  }

  static String _getAccount(Uri uri) {
    try {
      String path = Uri.decodeComponent(uri.path);
      if (path.startsWith("/")) {
        path = path.substring(1, path.length);
      }
      // Parse account name from documented auth URI
      // otpauth://totp/ACCOUNT?secret=SUPERSECRET&issuer=SERVICE
      if (uri.queryParameters.containsKey("issuer") && !path.contains(":")) {
        return path;
      }
      return path.split(':')[1];
    } catch (e) {
      return "";
    }
  }

  static Code fromExportJson(Map rawJson) {
    try {
      Code resultCode = Code.fromOTPAuthUrl(
        rawJson['rawData'],
        display: CodeDisplay.fromJson(rawJson['display']),
      );
      return resultCode;
    } catch (e) {
      debugPrint("Failed to parse code from export json $e");
      rethrow;
    }
  }

  Map<String, dynamic> toExportJson() {
    return {
      'rawData': rawData,
      if (display != null) 'display': display?.toJson(),
    };
  }

  static String _getIssuer(Uri uri) {
    try {
      if (uri.queryParameters.containsKey("issuer")) {
        String issuerName = uri.queryParameters['issuer']!;
        // Handle issuer name with period
        // See https://github.com/ente-io/ente/pull/77
        if (issuerName.contains("period=")) {
          return issuerName.substring(0, issuerName.indexOf("period="));
        }
        return issuerName;
      }
      final String path = Uri.decodeComponent(uri.path);
      return path.split(':')[0].substring(1);
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

  static int _getCounter(Uri uri) {
    try {
      final bool hasCounterKey = uri.queryParameters.containsKey('counter');
      if (!hasCounterKey) {
        return 0;
      }
      return int.parse(uri.queryParameters['counter']!);
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
    if (uri.host == "totp" || uri.host == "steam") {
      return Type.totp;
    } else if (uri.host == "hotp") {
      return Type.hotp;
    }
    throw UnsupportedError("Unsupported format with host ${uri.host}");
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
        other.counter == counter &&
        other.type == type &&
        other.rawData == rawData &&
        other.display == display;
  }

  @override
  int get hashCode {
    return account.hashCode ^
        issuer.hashCode ^
        digits.hashCode ^
        period.hashCode ^
        secret.hashCode ^
        type.hashCode ^
        counter.hashCode ^
        rawData.hashCode ^
        display.hashCode;
  }

  @override
  String toString() {
    return 'Code(account: $account, issuer: $issuer, digits: $digits, period: $period, secret: $secret, algorithm: $algorithm, type: $type, counter: $counter, rawData: $rawData, display: $display)';
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
