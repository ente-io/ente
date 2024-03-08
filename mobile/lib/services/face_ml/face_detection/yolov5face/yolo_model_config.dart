import "package:photos/services/face_ml/face_detection/yolov5face/yolo_face_detection_options.dart";
import "package:photos/services/face_ml/model_file.dart";

class YOLOModelConfig {
  final String modelPath;
  final FaceDetectionOptionsYOLO faceOptions;

  YOLOModelConfig({
    required this.modelPath,
    required this.faceOptions,
  });
}

final YOLOModelConfig yoloV5FaceS640x640DynamicBatchonnx = YOLOModelConfig(
  modelPath: ModelFile.yoloV5FaceS640x640DynamicBatchonnx,
  faceOptions: FaceDetectionOptionsYOLO(
    minScoreSigmoidThreshold: 0.8,
    iouThreshold: 0.4,
    inputWidth: 640,
    inputHeight: 640,
  ),
);
