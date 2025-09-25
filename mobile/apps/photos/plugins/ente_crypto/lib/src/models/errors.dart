class KeyDerivationError extends Error {}

class LoginKeyDerivationError extends Error {}

class CryptoErr implements Exception {
  final String message;
  final dynamic originalException;

  CryptoErr(this.message, [this.originalException]);

  @override
  String toString() {
    if (originalException != null) {
      return 'CryptoErr: $message\nCaused by: $originalException';
    }
    return 'CryptoErr: $message';
  }
}
