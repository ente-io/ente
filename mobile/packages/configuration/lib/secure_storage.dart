import 'src/secure_storage/secure_storage_interface.dart';
import 'src/secure_storage/secure_storage_stub.dart'
    if (dart.library.io) 'src/secure_storage/secure_storage_io.dart';

export 'src/secure_storage/secure_storage_interface.dart';

SecureStorage createSecureStorage() => createSecureStorageImpl();
