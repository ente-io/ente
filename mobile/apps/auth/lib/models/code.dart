import 'dart:convert';
import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:ente_auth/models/code_display.dart';
import 'package:ente_auth/utils/totp_util.dart';
import 'package:logging/logging.dart';

class Code {
  static const defaultDigits = 6;
  static const steamDigits = 5;
  static const defaultPeriod = 30;
  static const yandexDigits = 8;
  static const yandexSecretLength = 16;
  static const yandexFullSecretLength = 26;
  static const yandexDefaultIssuer = 'Yandex';

  int? generatedID;
  final String account;
  final String issuer;
  final int digits;
  final int period;
  final String secret;
  final Algorithm algorithm;
  final Type type;
  final String? pin;

  /// otpauth url in the code
  final String rawData;
  final int counter;
  bool? hasSynced;

  final CodeDisplay display;

  bool get isPinned => display.pinned;

  bool get isTrashed => display.trashed;
  String get note => display.note;

  final Object? err;
  bool get hasError => err != null;

  /// Stable identifier for UI selection state and other transient UI features.
  ///
  /// This key ensures selection consistency across sync operations and local changes:
  /// - Uses [generatedID] when available (after code is persisted to database)
  /// - Falls back to [rawData] for unpersisted codes (before first save)
  ///
  /// The fallback strategy ensures that:
  /// 1. Selections survive the transition from local-only to synced codes
  /// 2. Each persisted code has a unique, stable identifier
  /// 3. UI state reconciliation can map old keys to new keys during sync
  ///
  /// See [CodeDisplayStore.reconcileSelections] for selection state management.
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
    this.pin,
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
    String? pin,
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
    final String? updatedPin = pin ?? this.pin;
    final bool isYandex = updatedPin != null;
    final String effectiveSecret =
        isYandex ? _normalizeYandexSecret(updatedSecret) : updatedSecret;
    final int effectiveDigits = isYandex ? yandexDigits : updatedDigits;
    final int effectivePeriod = isYandex ? defaultPeriod : updatePeriod;
    final Algorithm effectiveAlgo = isYandex ? Algorithm.sha256 : updatedAlgo;
    final Type effectiveType = isYandex ? Type.totp : updatedType;

    return Code(
      updateAccount,
      updateIssuer,
      effectiveDigits,
      effectivePeriod,
      effectiveSecret,
      effectiveAlgo,
      effectiveType,
      updatedCounter,
      _buildOtpAuthUrl(
        type: effectiveType,
        account: updateAccount,
        issuer: updateIssuer,
        secret: effectiveSecret,
        algorithm: effectiveAlgo,
        digits: effectiveDigits,
        period: effectivePeriod,
        counter: updatedCounter,
        pin: updatedPin,
      ),
      generatedID: generatedID,
      display: updatedDisplay,
      pin: updatedPin,
    );
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
    String? pin,
  }) {
    final bool isYandex = pin != null;
    final String effectiveSecret =
        isYandex ? _normalizeYandexSecret(secret) : secret;
    final int effectiveDigits = isYandex ? yandexDigits : digits;
    final int effectivePeriod = isYandex ? defaultPeriod : period;
    final Algorithm effectiveAlgorithm =
        isYandex ? Algorithm.sha256 : algorithm;
    final Type effectiveType = isYandex ? Type.totp : type;

    return Code(
      account,
      issuer,
      effectiveDigits,
      effectivePeriod,
      effectiveSecret,
      effectiveAlgorithm,
      effectiveType,
      0,
      _buildOtpAuthUrl(
        type: effectiveType,
        account: account,
        issuer: issuer,
        secret: effectiveSecret,
        algorithm: effectiveAlgorithm,
        digits: effectiveDigits,
        period: effectivePeriod,
        counter: 0,
        pin: pin,
      ),
      display: display ?? CodeDisplay(),
      pin: pin,
    );
  }

  static Code fromOTPAuthUrl(String rawData, {CodeDisplay? display}) {
    Uri uri = Uri.parse(rawData);
    final String? pin = _getPin(uri);
    final bool isYandex = _isYandexCode(uri, pin);
    if (isYandex && pin == null) {
      throw UnsupportedError('Missing Yandex PIN');
    }
    final issuer = _getIssuer(uri, isYandex);
    final account = _getAccount(uri, issuer);

    try {
      final code = Code(
        account,
        issuer,
        _getDigits(uri, isYandex),
        _getPeriod(uri, isYandex),
        _getSecret(uri, isYandex),
        _getAlgorithm(uri, isYandex),
        _getType(uri),
        _getCounter(uri),
        rawData,
        display: CodeDisplay.fromUri(uri) ?? CodeDisplay(),
        pin: pin,
      );
      return code;
    } catch (e) {
      // if account name contains # without encoding,
      // rest of the url are treated as url fragment
      if (rawData.contains("#")) {
        return Code.fromOTPAuthUrl(rawData.replaceAll("#", '%23'));
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
      // Parse account name from documented auth URI
      // otpauth://totp/ACCOUNT?secret=SUPERSECRET&issuer=SERVICE
      if (uri.queryParameters.containsKey("issuer") && !path.contains(":")) {
        return path;
      }
      // handle case where issuer name contains colon
      if (path.startsWith('$issuer:')) {
        return path.substring(issuer.length + 1);
      }
      return path.substring(
        path.indexOf(':') + 1,
      ); // return data after first colon
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

  static String _getIssuer(Uri uri, [bool isYandex = false]) {
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
      if (!path.contains(':') && isYandex) {
        return yandexDefaultIssuer;
      }
      return path.split(':')[0].substring(1);
    } catch (e) {
      return "";
    }
  }

  static int _getDigits(Uri uri, [bool isYandex = false]) {
    if (isYandex) {
      return yandexDigits;
    }
    try {
      return int.parse(uri.queryParameters['digits']!);
    } catch (e) {
      if (uri.host == "steam") {
        return steamDigits;
      }
      return defaultDigits;
    }
  }

  static int _getPeriod(Uri uri, [bool isYandex = false]) {
    if (isYandex) {
      return defaultPeriod;
    }
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

  static Algorithm _getAlgorithm(Uri uri, [bool isYandex = false]) {
    if (isYandex) {
      return Algorithm.sha256;
    }
    try {
      final algorithm =
          uri.queryParameters['algorithm'].toString().toLowerCase();
      if (algorithm == "sha256" || "algorithm.sha256" == algorithm) {
        return Algorithm.sha256;
      } else if (algorithm == "sha512" || "algorithm.sha512" == algorithm) {
        return Algorithm.sha512;
      }
    } catch (e) {
      // nothing
    }
    return Algorithm.sha1;
  }

  static Type _getType(Uri uri) {
    if (uri.host == "totp" || uri.host == "yaotp" || uri.host == "yandex") {
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
        _hasSameCanonicalData(other) &&
        ((pin != null || other.pin != null) || other.rawData == rawData);
  }

  @override
  int get hashCode {
    final int canonicalHash = Object.hash(
      account,
      issuer,
      digits,
      period,
      secret,
      pin,
      type,
      counter,
    );
    return pin != null ? canonicalHash : Object.hash(canonicalHash, rawData);
  }

  bool _hasSameCanonicalData(Code other) {
    return other.account == account &&
        other.issuer == issuer &&
        other.digits == digits &&
        other.period == period &&
        other.secret == secret &&
        other.counter == counter &&
        other.pin == pin &&
        other.type == type;
  }

  static String _getSecret(Uri uri, [bool isYandex = false]) {
    final String secret = getSanitizedSecret(uri.queryParameters['secret']!);
    return isYandex ? _normalizeYandexSecret(secret) : secret;
  }

  static String? _getPin(Uri uri) {
    final String? pin = uri.queryParameters['pin'];
    if (pin == null || pin.isEmpty) {
      return null;
    }

    final String sanitizedPin =
        pin.trim().replaceAll(' ', '').replaceAll('-', '');
    if (RegExp(r'^\d{4,16}$').hasMatch(sanitizedPin)) {
      return sanitizedPin;
    }

    try {
      final decodedPin = utf8.decode(base32.decode(sanitizedPin.toUpperCase()));
      if (RegExp(r'^\d{4,16}$').hasMatch(decodedPin)) {
        return decodedPin;
      }
    } catch (e) {
      // Let the error below surface for invalid pins.
    }

    throw UnsupportedError('Invalid Yandex PIN');
  }

  static bool _isYandexCode(Uri uri, String? pin) {
    return uri.host == 'yaotp' ||
        uri.host == 'yandex' ||
        uri.queryParameters.containsKey('pin') ||
        pin != null;
  }

  static String _normalizeYandexSecret(String secret) {
    final Uint8List decodedSecret =
        base32.decode(_sanitizeYandexSecret(secret));
    _validateYandexSecret(decodedSecret);

    final Uint8List normalizedSecret =
        decodedSecret.length == yandexSecretLength
            ? decodedSecret
            : Uint8List.fromList(decodedSecret.sublist(0, yandexSecretLength));
    return base32.encode(normalizedSecret).replaceAll('=', '').toUpperCase();
  }

  static String _sanitizeYandexSecret(String secret) {
    return getSanitizedSecret(secret).replaceAll('-', '');
  }

  static void _validateYandexSecret(Uint8List secret) {
    if (secret.length != yandexSecretLength &&
        secret.length != yandexFullSecretLength) {
      throw UnsupportedError(
        'Invalid Yandex secret length: ${secret.length} bytes',
      );
    }

    if (secret.length == yandexSecretLength) {
      return;
    }

    final int originalChecksum =
        ((secret[secret.length - 2] & 0x0F) << 8) | secret[secret.length - 1];

    int accum = 0;
    int accumBits = 0;
    int inputTotalBitsAvailable = secret.length * 8 - 12;
    int inputIndex = 0;
    int inputBitsAvailable = 8;

    while (inputTotalBitsAvailable > 0) {
      int requiredBits = 13 - accumBits;
      if (inputTotalBitsAvailable < requiredBits) {
        requiredBits = inputTotalBitsAvailable;
      }

      while (requiredBits > 0) {
        int curInput = secret[inputIndex] & ((1 << inputBitsAvailable) - 1);
        final int bitsToRead = requiredBits < inputBitsAvailable
            ? requiredBits
            : inputBitsAvailable;

        curInput >>= inputBitsAvailable - bitsToRead;
        accum = ((accum << bitsToRead) | curInput) & 0xFFFF;

        inputTotalBitsAvailable -= bitsToRead;
        requiredBits -= bitsToRead;
        inputBitsAvailable -= bitsToRead;
        accumBits += bitsToRead;

        if (inputBitsAvailable == 0) {
          inputIndex += 1;
          inputBitsAvailable = 8;
        }
      }

      if (accumBits == 13) {
        accum ^= 0x18F3;
      }
      accumBits = 16 - _countLeadingZeros(accum);
    }

    if (accum != originalChecksum) {
      throw UnsupportedError('Yandex secret checksum invalid');
    }
  }

  static int _countLeadingZeros(int value) {
    if (value == 0) {
      return 16;
    }

    int n = 0;
    int current = value;
    if ((current & 0xFF00) == 0) {
      n += 8;
      current <<= 8;
    }
    if ((current & 0xF000) == 0) {
      n += 4;
      current <<= 4;
    }
    if ((current & 0xC000) == 0) {
      n += 2;
      current <<= 2;
    }
    if ((current & 0x8000) == 0) {
      n += 1;
    }

    return n;
  }

  static String _buildOtpAuthUrl({
    required Type type,
    required String account,
    required String issuer,
    required String secret,
    required Algorithm algorithm,
    required int digits,
    required int period,
    required int counter,
    String? pin,
  }) {
    final String encodedIssuer = Uri.encodeQueryComponent(issuer);
    final bool isYandex = pin != null;
    final String host = isYandex ? 'yaotp' : type.name;
    final String normalizedSecret =
        isYandex ? _normalizeYandexSecret(secret) : secret;
    final StringBuffer query = StringBuffer()
      ..write(
        'algorithm=${(isYandex ? Algorithm.sha256 : algorithm).name.toUpperCase()}',
      )
      ..write('&digits=${isYandex ? yandexDigits : digits}')
      ..write('&issuer=$encodedIssuer')
      ..write('&period=${isYandex ? defaultPeriod : period}')
      ..write('&secret=$normalizedSecret');

    if (type == Type.hotp && !isYandex) {
      query.write('&counter=$counter');
    }
    if (isYandex) {
      query.write('&pin=${_encodeYandexPin(pin)}');
    }

    return 'otpauth://$host/$issuer:$account?${query.toString()}';
  }

  static String _encodeYandexPin(String pin) {
    return base32
        .encode(Uint8List.fromList(utf8.encode(pin)))
        .replaceAll('=', '')
        .toUpperCase();
  }
}

enum Type {
  totp,
  hotp,
  steam;

  bool get isTOTPCompatible => this == totp || this == steam;
}

enum Algorithm { sha1, sha256, sha512 }
