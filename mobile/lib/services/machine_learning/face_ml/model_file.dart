mixin ModelFile {
  static const String faceDetectionBackWeb =
      'assets/models/blazeface/blazeface_back_ente_web.tflite';
  // TODO: which of the two mobilefacenet model should I use now??
  // static const String faceEmbeddingEnte =
  // 'assets/models/mobilefacenet/mobilefacenet_ente_web.tflite';
  static const String faceEmbeddingEnte =
      'assets/models/mobilefacenet/mobilefacenet_unq_TF211.tflite';
  static const String yoloV5FaceS640x640DynamicBatchonnx =
      'assets/models/yolov5face/yolov5s_face_640_640_dynamic.onnx';
}
