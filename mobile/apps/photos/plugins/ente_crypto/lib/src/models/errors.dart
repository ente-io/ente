class KeyDerivationError extends Error {}

class LoginKeyDerivationError extends Error {}

class StreamPullErr implements Exception {
  final String message;
  final dynamic originalException;

  StreamPullErr(this.message, [this.originalException]);

  @override
  String toString() {
    if (originalException != null) {
      return 'StreamPullErr: $message\nCaused by: $originalException';
    }
    return 'StreamPullErr: $message';
  }
}

extension FutureErrorHandling<T> on Future<T> {
  Future<T> unwrapExceptionInComputer() {
    return catchError((e) {
      final msg = e.toString();
      if (msg.contains(kPartialReadErrorTag)) {
        throw PartialReadException(msg);
      }
      throw e;
    });
  }
}

const kPartialReadErrorTag = 'PartialRead';
const kStreamPullError = 'crypto_secretstream_xchacha20poly1305_pull';

// Exception counterpart for upstream handling via catchError chains
class PartialReadException implements Exception {
  final String message;
  PartialReadException(this.message);

  @override
  String toString() => 'PartialReadException: $message';
}
