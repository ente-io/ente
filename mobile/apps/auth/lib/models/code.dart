import 'dart:convert';

import 'package:ente_auth/models/code_display.dart';
import 'package:ente_auth/utils/totp_util.dart';
import 'package:logging/logging.dart';

class Code {
  static const defaultDigits = 6;
  static const steamDigits = 5;
  static const defaultPeriod = 30;

  int? generatedID;
  final String account;
  final String issuer;
  final int digits;
  final int period;
  final String secret;
  final Algorithm algorithm;
  final Type type;

  // Original otpauth URL.
  final String rawData;

  /// Website associated with this code, when the OTP URI includes a `url`
  /// query parameter.
  String? get websiteUrl {
    final uri = Uri.tryParse(rawData);
    return _validatedWebsiteUrl(uri?.queryParameters['url']);
  }

  static String? _validatedWebsiteUrl(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final website = Uri.tryParse(
      trimmed.contains('://') ? trimmed : 'https://$trimmed',
    );
    if (website == null ||
        (website.scheme != 'https' && website.scheme != 'http') ||
        website.host.isEmpty ||
        website.userInfo.isNotEmpty) {
      return null;
    }
    return website.toString();
  }

  final int counter;
  bool? hasSynced;
  int? createdAt;

  final CodeDisplay display;

  bool get isPinned => display.pinned;

  bool get isTrashed => display.trashed;
  String get note => display.note;

  final Object? err;
  bool get hasError => err != null;

  // Unsaved codes use rawData until the first save assigns generatedID.
  String get selectionKey => generatedID?.toString() ?? rawData;

  String get issuerAccount =>
      account.isNotEmpty ? '$issuer ($account)' : issuer;

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
    required this.display,
    this.err,
  });

  factory Code.withError(Object error, String rawData) {
    return Code(
      "",
      "",
      0,
      0,
      "",
      Algorithm.sha1,
      Type.totp,
      0,
      rawData,
      err: error,
      display: CodeDisplay(),
    );
  }

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
    String? websiteUrl,
    bool replaceWebsiteUrl = false,
  }) {
    final String updateAccount = account ?? this.account;
    final String updateIssuer = issuer ?? this.issuer;
    final int updatedDigits = digits ?? this.digits;
    final int updatePeriod = period ?? this.period;
    final String updatedSecret = secret ?? this.secret;
    final Algorithm updatedAlgo = algorithm ?? this.algorithm;
    final Type updatedType = type ?? this.type;
    final int updatedCounter = counter ?? this.counter;
    final CodeDisplay updatedDisplay = display ?? this.display;
    final uri = Uri.tryParse(rawData);
    final queryParameters = <String, String>{...?uri?.queryParameters};
    queryParameters.remove('codeDisplay');
    queryParameters['algorithm'] = updatedAlgo.name.toUpperCase();
    queryParameters['digits'] = '$updatedDigits';
    queryParameters['issuer'] = updateIssuer;
    queryParameters['period'] = '$updatePeriod';
    queryParameters['secret'] = updatedSecret;
    if (updatedType == Type.hotp) {
      queryParameters['counter'] = '$updatedCounter';
    } else {
      queryParameters.remove('counter');
    }
    final url = replaceWebsiteUrl ? websiteUrl : this.websiteUrl;
    final validatedUrl = _validatedWebsiteUrl(url);
    if (validatedUrl == null) {
      queryParameters.remove('url');
    } else {
      queryParameters['url'] = validatedUrl;
    }
    final updatedRawData = Uri(
      scheme: 'otpauth',
      host: updatedType.name,
      path: '/$updateIssuer:$updateAccount',
      queryParameters: queryParameters,
    ).toString();

    return Code(
      updateAccount,
      updateIssuer,
      updatedDigits,
      updatePeriod,
      updatedSecret,
      updatedAlgo,
      updatedType,
      updatedCounter,
      updatedRawData,
      generatedID: generatedID,
      display: updatedDisplay,
    )..createdAt = createdAt;
  }

  static Code fromAccountAndSecret(
    Type type,
    String account,
    String issuer,
    String secret,
    CodeDisplay? display,
    int digits, {
    Algorithm algorithm = Algorithm.sha1,
    int period = defaultPeriod,
    String? websiteUrl,
  }) {
    final website = _validatedWebsiteUrl(websiteUrl);
    final rawData = Uri(
      scheme: 'otpauth',
      host: type.name,
      path: '/$issuer:$account',
      queryParameters: {
        'algorithm': algorithm.name.toUpperCase(),
        'digits': '$digits',
        'issuer': issuer,
        'period': '$period',
        'secret': secret,
        'url': ?website,
      },
    ).toString();
    return Code(
      account,
      issuer,
      digits,
      period,
      secret,
      algorithm,
      type,
      0,
      rawData,
      display: display ?? CodeDisplay(),
    );
  }

  static Code fromOTPAuthUrl(String rawData, {CodeDisplay? display}) {
    final uri = Uri.tryParse(rawData);
    if (uri == null) {
      throw const FormatException('OTP URL is malformed');
    }
    final issuer = _getIssuer(uri);
    final account = _getAccount(uri, issuer);

    try {
      final code = Code(
        account,
        issuer,
        _getDigits(uri),
        _getPeriod(uri),
        getSanitizedSecret(uri.queryParameters['secret']!),
        _getAlgorithm(uri),
        _getType(uri),
        _getCounter(uri),
        rawData,
        display: display ?? CodeDisplay.fromUri(uri) ?? CodeDisplay(),
      );
      return code;
    } catch (e) {
      // Retry after encoding an unescaped # in the account name.
      if (rawData.contains("#")) {
        return Code.fromOTPAuthUrl(
          rawData.replaceAll("#", '%23'),
          display: display,
        );
      } else {
        Logger(
          "Code",
        ).warning('Error while parsing code for issuer $issuer, $account', e);
        rethrow;
      }
    }
  }

  static String _getAccount(Uri uri, String issuer) {
    try {
      String path = Uri.decodeComponent(uri.path);
      if (path.startsWith("/")) {
        path = path.substring(1, path.length);
      }
      if (uri.queryParameters.containsKey("issuer") && !path.contains(":")) {
        return path;
      }
      if (path.startsWith('$issuer:')) {
        return path.substring(issuer.length + 1);
      }
      return path.substring(path.indexOf(':') + 1);
    } catch (e, s) {
      Logger('_getAccount').severe('Error while parsing account', e, s);
      return "";
    }
  }

  static Code fromExportJson(Map rawJson) {
    Code resultCode = Code.fromOTPAuthUrl(
      rawJson['rawData'],
      display: CodeDisplay.fromJson(rawJson['display']),
    );
    return resultCode;
  }

  String toOTPAuthUrlFormat() {
    final uri = Uri.parse(rawData.replaceAll("#", '%23'));
    final query = {...uri.queryParameters};
    query["codeDisplay"] = jsonEncode(display.toJson());

    final newUri = uri.replace(queryParameters: query);
    return jsonEncode(newUri.toString());
  }

  static String _getIssuer(Uri uri) {
    try {
      if (uri.queryParameters.containsKey("issuer")) {
        String issuerName = uri.queryParameters['issuer']!;
        // Handle issuer name with period
        // See https://github.com/ente/ente/pull/77
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
      if (uri.host == "steam") {
        return steamDigits;
      }
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
      final algorithm = uri.queryParameters['algorithm']
          .toString()
          .toLowerCase();
      if (algorithm == "sha256" || "algorithm.sha256" == algorithm) {
        return Algorithm.sha256;
      } else if (algorithm == "sha512" || "algorithm.sha512" == algorithm) {
        return Algorithm.sha512;
      }
    } catch (e) {
      // Fall back to SHA-1.
    }
    return Algorithm.sha1;
  }

  static Type _getType(Uri uri) {
    if (uri.host == "totp") {
      return Type.totp;
    } else if (uri.host == "steam") {
      return Type.steam;
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
        counter.hashCode ^
        rawData.hashCode;
  }
}

enum Type {
  totp,
  hotp,
  steam;

  bool get isTOTPCompatible => this == totp || this == steam;

  bool get canShareCodes => this == totp || this == steam;
}

enum Algorithm { sha1, sha256, sha512 }
