import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';

const MethodChannel _defaultChannel = MethodChannel('ente.io/local_auth_linux');
const String linuxLocalAuthPolkitActionId = 'io.ente.auth.unlock';

class LinuxLocalAuthSetupStatus {
  const LinuxLocalAuthSetupStatus({
    required this.actionId,
    required this.policyAssetPath,
    required this.polkitAvailable,
    required this.policyInstalled,
    required this.isFlatpak,
    this.errorMessage,
  });

  factory LinuxLocalAuthSetupStatus.fromMap(Map<Object?, Object?> map) {
    return LinuxLocalAuthSetupStatus(
      actionId: map['actionId'] as String? ?? linuxLocalAuthPolkitActionId,
      policyAssetPath: map['policyAssetPath'] as String? ?? _policyAssetPath,
      polkitAvailable: map['polkitAvailable'] as bool? ?? false,
      policyInstalled: map['policyInstalled'] as bool? ?? false,
      isFlatpak: map['isFlatpak'] as bool? ?? _isFlatpak,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  final String actionId;
  final String policyAssetPath;
  final bool polkitAvailable;
  final bool policyInstalled;
  final bool isFlatpak;
  final String? errorMessage;

  bool get setupRequired => polkitAvailable && !policyInstalled;

  String get policyInstallCommand {
    if (isFlatpak) {
      return '''
app_id="\${FLATPAK_ID:-io.ente.auth}"
install_dir="\$(flatpak info --show-location "\$app_id")"
policy="\$install_dir/files/share/enteauth/data/flutter_assets/assets/polkit/io.ente.auth.policy"
sudo install -D -o root -g root -m 0644 "\$policy" /usr/share/polkit-1/actions/io.ente.auth.policy
if command -v chcon >/dev/null 2>&1; then sudo chcon system_u:object_r:usr_t:s0 /usr/share/polkit-1/actions/io.ente.auth.policy || true; fi
pkaction --action-id $actionId --verbose''';
    }
    return '''
sudo install -D -o root -g root -m 0644 "$policyAssetPath" /usr/share/polkit-1/actions/io.ente.auth.policy
if command -v chcon >/dev/null 2>&1; then sudo chcon system_u:object_r:usr_t:s0 /usr/share/polkit-1/actions/io.ente.auth.policy || true; fi
pkaction --action-id $actionId --verbose''';
  }
}

bool get _isFlatpak =>
    Platform.environment.containsKey('FLATPAK_ID') ||
    File('/.flatpak-info').existsSync();

String get _policyAssetPath => _isFlatpak
    ? '/app/share/enteauth/data/flutter_assets/assets/polkit/io.ente.auth.policy'
    : '/usr/share/enteauth/data/flutter_assets/assets/polkit/io.ente.auth.policy';

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
        "Linux Polkit authentication doesn't support the biometricOnly parameter.",
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

  Future<LinuxLocalAuthSetupStatus> getSetupStatus() async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'getSetupStatus',
    );
    return LinuxLocalAuthSetupStatus.fromMap(
      result ?? const <Object?, Object?>{},
    );
  }
}

LocalAuthException _localAuthExceptionForPlatformException(
  PlatformException error,
) {
  final code = switch (error.code) {
    'authentication_canceled' => LocalAuthExceptionCode.userCanceled,
    'setup_required' => LocalAuthExceptionCode.noCredentialsSet,
    'polkit_unavailable' => LocalAuthExceptionCode.deviceError,
    'authentication_failed' => LocalAuthExceptionCode.unknownError,
    'polkit_error' => LocalAuthExceptionCode.unknownError,
    _ => LocalAuthExceptionCode.unknownError,
  };
  return LocalAuthException(code: code, description: error.message);
}
