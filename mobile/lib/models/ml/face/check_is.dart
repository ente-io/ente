import 'package:photos/models/ml/face/box.dart';

enum FaceCheckStatus {
  fallback,    // Undefined or not yet evaluated
  recognized,  // Face is recognized
  suggest,     // Face is close but not recognized; can be suggested
  rejected,    // Face not recognized and not suggestable
}

extension FaceBoxCheckExtension on FaceBox {
  FaceCheckStatus get checkStatus {
    if (check == null || check == fallbackConfidence) {
      return FaceCheckStatus.fallback;
    } else if (check >= 0.8) {
      return FaceCheckStatus.recognized;
    } else if (check >= 0.6) {
      return FaceCheckStatus.suggest;
    } else {
      return FaceCheckStatus.rejected;
    }
  }

  bool get isRecognized => checkStatus == FaceCheckStatus.recognized;

  bool get isSuggestable =>
      checkStatus == FaceCheckStatus.suggest || checkStatus == FaceCheckStatus.fallback;

  bool get isRejected => checkStatus == FaceCheckStatus.rejected;
}
