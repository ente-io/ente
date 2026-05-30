import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';

const MethodChannel _defaultChannel = MethodChannel('ente.io/local_auth_linux');

class LocalAuthLinux extends LocalAuthPlatform {
  LocalAuthLinux({@visibleForTesting MethodChannel? channel})
    : _channel = channel ?? _defaultChannel;

  final MethodChannel _channel;
  bool _isAuthenticating = false;

  static void registerWith() {
    LocalAuthPlatform.instance = LocalAuthLinux();
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    assert(localizedReason.isNotEmpty);

    if (options.biometricOnly) {
      throw UnsupportedError(
        "Linux PAM authentication doesn't support the biometricOnly parameter.",
      );
    }
    if (_isAuthenticating) {
      throw const LocalAuthException(
        code: LocalAuthExceptionCode.authInProgress,
      );
    }

    _isAuthenticating = true;
    try {
      return await _channel.invokeMethod<bool>(
            'authenticate',
            <String, Object?>{'localizedReason': localizedReason},
          ) ??
          false;
    } on PlatformException catch (e) {
      throw _localAuthExceptionForPlatformException(e);
    } finally {
      _isAuthenticating = false;
    }
  }

  @override
  Future<bool> deviceSupportsBiometrics() async => false;

  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async =>
      <BiometricType>[];

  @override
  Future<bool> isDeviceSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isDeviceSupported') ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> stopAuthentication() async => false;
}

LocalAuthException _localAuthExceptionForPlatformException(
  PlatformException error,
) {
  final code = switch (error.code) {
    'authentication_canceled' => LocalAuthExceptionCode.userCanceled,
    'ui_unavailable' => LocalAuthExceptionCode.uiUnavailable,
    'pam_unavailable' ||
    'unsupported_runtime' ||
    'account_unavailable' => LocalAuthExceptionCode.deviceError,
    'authentication_failed' => LocalAuthExceptionCode.unknownError,
    'pam_error' => LocalAuthExceptionCode.unknownError,
    _ => LocalAuthExceptionCode.unknownError,
  };
  return LocalAuthException(code: code, description: error.message);
}
