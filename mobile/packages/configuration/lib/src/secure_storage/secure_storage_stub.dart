import 'secure_storage_interface.dart';

SecureStorage createSecureStorageImpl() {
  throw SecureStorageException(
    'Secure storage is not supported on this platform.',
  );
}
