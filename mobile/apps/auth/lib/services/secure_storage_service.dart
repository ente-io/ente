// Re-export the common SecureStorageService from ente_configuration package
export 'package:ente_configuration/secure_storage_service.dart';

/// Auth app-specific secure storage keys
class AuthSecureStorageKeys {
  AuthSecureStorageKeys._();

  /// Key for storing the local backup password
  static const autoBackupPasswordKey = 'autoBackupPassword';
}
