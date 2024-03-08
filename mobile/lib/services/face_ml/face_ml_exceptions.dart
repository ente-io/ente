
class GeneralFaceMlException implements Exception {
  final String message;

  GeneralFaceMlException(this.message);

  @override
  String toString() => 'GeneralFaceMlException: $message';
}

class CouldNotRetrieveAnyFileData implements Exception {}

class CouldNotInitializeFaceDetector implements Exception {}

class CouldNotRunFaceDetector implements Exception {}

class CouldNotWarpAffine implements Exception {}

class CouldNotInitializeFaceEmbeddor implements Exception {}

class InputProblemFaceEmbeddor implements Exception {
  final String message;

  InputProblemFaceEmbeddor(this.message);

  @override
  String toString() => 'InputProblemFaceEmbeddor: $message';
}

class CouldNotRunFaceEmbeddor implements Exception {}