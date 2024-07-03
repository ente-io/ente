import "dart:convert";

class Embedding {
  final int fileID;
  final Model model;
  final List<double> embedding;
  int? updationTime;

  bool get isEmpty => embedding.isEmpty;

  Embedding({
    required this.fileID,
    required this.model,
    required this.embedding,
    this.updationTime,
  });

  factory Embedding.empty(int fileID, Model model) {
    return Embedding(
      fileID: fileID,
      model: model,
      embedding: <double>[],
    );
  }

  static List<double> decodeEmbedding(String embedding) {
    return List<double>.from(jsonDecode(embedding) as List);
  }

  static String encodeEmbedding(List<double> embedding) {
    return jsonEncode(embedding);
  }
}

enum Model {
  onnxClip,
  ggmlClip,
}

extension ModelExtension on Model {
  String get name => serialize(this);
}

String serialize(Model model) {
  switch (model) {
    case Model.onnxClip:
      return 'onnx-clip';
    case Model.ggmlClip:
      return 'ggml-clip';
    default:
      throw Exception('$model is not a valid Model');
  }
}

Model deserialize(String model) {
  switch (model) {
    case 'onnx-clip':
      return Model.onnxClip;
    case 'ggml-clip':
      return Model.ggmlClip;
    default:
      throw Exception('$model is not a valid Model');
  }
}
