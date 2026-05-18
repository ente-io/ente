import 'package:logging/logging.dart';
import "package:photos/services/machine_learning/ml_model.dart";

/// Pet face detection model (YOLOv5s-face with 3 keypoints, FP16).
/// Model: yolov5s_pet_face_fp16_V2.onnx — detects pet faces with left_eye, right_eye, nose landmarks.
///
/// Model size: ~14.8 MB.
class PetFaceDetectionService extends MlModel {
  static const kRemoteBucketModelPath = "yolov5s_pet_face_fp16_V2.onnx";
  static const kModelSha256 =
      "7876d97992eeb5f3a9f3b35eff5e0e133012928172a8b005093108d8c3ad2d1c";
  static const _modelName = "YOLOv5PetFace";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  String get modelSha256 => kModelSha256;

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
///
/// Model size: ~4.1 MB.
class PetFaceEmbeddingDogService extends MlModel {
  static const kRemoteBucketModelPath = "dog_face_embedding128.onnx";
  static const kModelSha256 =
      "fb04d781eb1f7adf6ce3432dc0c5873f16cc051b5c98c14c754afb39e2b92462";
  static const _modelName = "DogFaceByol128";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  String get modelSha256 => kModelSha256;

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
///
/// Model size: ~4.1 MB.
class PetFaceEmbeddingCatService extends MlModel {
  static const kRemoteBucketModelPath = "cat_face_embedding128.onnx";
  static const kModelSha256 =
      "32b10694a27f6404d2beaddbd64f07ad555f72dccb12ee60a7afe5dcf6aad6cd";
  static const _modelName = "CatFaceByol128";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  String get modelSha256 => kModelSha256;

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
///
/// Model size: ~15.0 MB.
class PetBodyDetectionService extends MlModel {
  static const kRemoteBucketModelPath = "yolov5s_object_fp16.onnx";
  static const kModelSha256 =
      "113f0c18632eb2c4f6deebcd40eb01c676492e9b43923c2d336e1b4012fce9ef";
  static const _modelName = "YOLOv5sPetBody";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  String get modelSha256 => kModelSha256;

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
///
/// Model size: ~4.6 MB.
class PetBodyEmbeddingDogService extends MlModel {
  static const kRemoteBucketModelPath = "dog_body_embedding192.onnx";
  static const kModelSha256 =
      "1d85aa20358137e30f11c2d0baa9a2248b9997928d501fe15365d1fc57522770";
  static const _modelName = "DogBody";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  String get modelSha256 => kModelSha256;

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
///
/// Model size: ~4.6 MB.
class PetBodyEmbeddingCatService extends MlModel {
  static const kRemoteBucketModelPath = "cat_body_embedding192.onnx";
  static const kModelSha256 =
      "62fb5891e61be69a96510d8ec56e7525a9541b0283e54574d27c86c9b4a26ddf";
  static const _modelName = "CatBody";

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  String get modelSha256 => kModelSha256;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('PetBodyEmbeddingCatService');

  @override
  String get modelName => _modelName;

  PetBodyEmbeddingCatService._privateConstructor();
  static final instance = PetBodyEmbeddingCatService._privateConstructor();
  factory PetBodyEmbeddingCatService() => instance;
}
