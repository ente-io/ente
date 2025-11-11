abstract class SecureStorage {
  Future<String?> read({required String key});

  Future<void> write({required String key, String? value});

  Future<bool> containsKey({required String key});

  Future<void> delete({required String key});
}

class SecureStorageException implements Exception {
  SecureStorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    final suffix = cause == null ? '' : ' ($cause)';
    return 'SecureStorageException: $message$suffix';
  }
}
