import "package:photos/services/machine_learning/face_ml/face_detection/face_detection_service.dart";
import "package:photos/services/machine_learning/face_ml/face_embedding/face_embedding_service.dart";
import "package:photos/services/machine_learning/ml_model.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_image_encoder.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_encoder.dart";

enum MLModels {
  faceDetection,
  faceEmbedding,
  clipImageEncoder,
  clipTextEncoder,
}

extension MLModelsExtension on MLModels {
  MlModel get model {
    switch (this) {
      case MLModels.faceDetection:
        return FaceDetectionService.instance;
      case MLModels.faceEmbedding:
        return FaceEmbeddingService.instance;
      case MLModels.clipImageEncoder:
        return ClipImageEncoder.instance;
      case MLModels.clipTextEncoder:
        return ClipTextEncoder.instance;
    }
  }

  bool get isIndexingModel {
    switch (this) {
      case MLModels.faceDetection:
      case MLModels.faceEmbedding:
      case MLModels.clipImageEncoder:
        return true;
      case MLModels.clipTextEncoder:
        return false;
    }
  }
}
