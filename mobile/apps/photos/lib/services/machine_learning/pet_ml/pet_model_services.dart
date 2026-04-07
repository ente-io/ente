import 'package:logging/logging.dart';
import "package:photos/services/machine_learning/ml_model.dart";

/// Pet face detection model (YOLOv5s-face with 3 keypoints, FP16).
/// Model: yolov5s_pet_face_fp16_V2.onnx — detects pet faces with left_eye, right_eye, nose landmarks.
class PetFaceDetectionService extends MlModel {
  static const kRemoteBucketModelPath = "yolov5s_pet_face_fp16_V2.onnx";
  static const _modelName = "YOLOv5PetFace";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('PetFaceDetectionService');

  @override
  String get modelName => _modelName;

  PetFaceDetectionService._privateConstructor();
  static final instance = PetFaceDetectionService._privateConstructor();
  factory PetFaceDetectionService() => instance;
}

/// Dog face embedding model (BYOL 128-d).
class PetFaceEmbeddingDogService extends MlModel {
  static const kRemoteBucketModelPath = "dog_face_embedding128.onnx";
  static const _modelName = "DogFaceByol128";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('PetFaceEmbeddingDogService');

  @override
  String get modelName => _modelName;

  PetFaceEmbeddingDogService._privateConstructor();
  static final instance = PetFaceEmbeddingDogService._privateConstructor();
  factory PetFaceEmbeddingDogService() => instance;
}

/// Cat face embedding model (BYOL 128-d).
class PetFaceEmbeddingCatService extends MlModel {
  static const kRemoteBucketModelPath = "cat_face_embedding128.onnx";
  static const _modelName = "CatFaceByol128";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('PetFaceEmbeddingCatService');

  @override
  String get modelName => _modelName;

  PetFaceEmbeddingCatService._privateConstructor();
  static final instance = PetFaceEmbeddingCatService._privateConstructor();
  factory PetFaceEmbeddingCatService() => instance;
}

/// Pet body detection model (YOLOv5s — COCO classes 15=cat, 16=dog).
class PetBodyDetectionService extends MlModel {
  static const kRemoteBucketModelPath = "yolov5s_object_fp16.onnx";
  static const _modelName = "YOLOv5sPetBody";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('PetBodyDetectionService');

  @override
  String get modelName => _modelName;

  PetBodyDetectionService._privateConstructor();
  static final instance = PetBodyDetectionService._privateConstructor();
  factory PetBodyDetectionService() => instance;
}

/// Dog body embedding model.
class PetBodyEmbeddingDogService extends MlModel {
  static const kRemoteBucketModelPath = "dog_body_embedding192.onnx";
  static const _modelName = "DogBody";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('PetBodyEmbeddingDogService');

  @override
  String get modelName => _modelName;

  PetBodyEmbeddingDogService._privateConstructor();
  static final instance = PetBodyEmbeddingDogService._privateConstructor();
  factory PetBodyEmbeddingDogService() => instance;
}

/// Cat body embedding model.
class PetBodyEmbeddingCatService extends MlModel {
  static const kRemoteBucketModelPath = "cat_body_embedding192.onnx";
  static const _modelName = "CatBody";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('PetBodyEmbeddingCatService');

  @override
  String get modelName => _modelName;

  PetBodyEmbeddingCatService._privateConstructor();
  static final instance = PetBodyEmbeddingCatService._privateConstructor();
  factory PetBodyEmbeddingCatService() => instance;
}
