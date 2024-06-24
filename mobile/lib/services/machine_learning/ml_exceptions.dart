
class GeneralFaceMlException implements Exception {
  final String message;

  GeneralFaceMlException(this.message);

  @override
  String toString() => 'GeneralFaceMlException: $message';
}

class ThumbnailRetrievalException implements Exception {
  final String message;
  final StackTrace stackTrace;

  ThumbnailRetrievalException(this.message, this.stackTrace);

  @override
  String toString() {
    return 'ThumbnailRetrievalException: $message\n$stackTrace';
  }
}

class CouldNotRetrieveAnyFileData implements Exception {}

class CouldNotRunFaceDetector implements Exception {}

class CouldNotWarpAffine implements Exception {}

class CouldNotRunFaceEmbeddor implements Exception {}