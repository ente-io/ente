import "package:photos/services/machine_learning/face_ml/face_detection/face_detection_service.dart";
import "package:photos/services/machine_learning/face_ml/face_embedding/face_embedding_service.dart";
import "package:photos/services/machine_learning/ml_model.dart";
import "package:photos/services/machine_learning/pet_ml/pet_model_services.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_image_encoder.dart";
import "package:photos/services/machine_learning/semantic_search/clip/clip_text_encoder.dart";

enum MLModels {
  faceDetection,
  faceEmbedding,
  clipImageEncoder,
  clipTextEncoder,
  petFaceDetection,
  petFaceEmbeddingDog,
  petFaceEmbeddingCat,
  petBodyDetection,
  petBodyEmbeddingDog,
  petBodyEmbeddingCat,
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
      case MLModels.petFaceDetection:
        return PetFaceDetectionService.instance;
      case MLModels.petFaceEmbeddingDog:
        return PetFaceEmbeddingDogService.instance;
      case MLModels.petFaceEmbeddingCat:
        return PetFaceEmbeddingCatService.instance;
      case MLModels.petBodyDetection:
        return PetBodyDetectionService.instance;
      case MLModels.petBodyEmbeddingDog:
        return PetBodyEmbeddingDogService.instance;
      case MLModels.petBodyEmbeddingCat:
        return PetBodyEmbeddingCatService.instance;
    }
  }

  bool get isIndexingModel {
    switch (this) {
      case MLModels.faceDetection:
      case MLModels.faceEmbedding:
      case MLModels.clipImageEncoder:
      case MLModels.petFaceDetection:
      case MLModels.petFaceEmbeddingDog:
      case MLModels.petFaceEmbeddingCat:
      case MLModels.petBodyDetection:
      case MLModels.petBodyEmbeddingDog:
      case MLModels.petBodyEmbeddingCat:
        return true;
      case MLModels.clipTextEncoder:
        return false;
    }
  }
}
