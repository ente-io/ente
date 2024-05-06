import "dart:typed_data" show Uint8List;

class FaceInfoForClustering {
  final String faceID;
  int? clusterId;
  final Uint8List embeddingBytes;
  final double faceScore;
  final double blurValue;
  final bool isSideways;

  FaceInfoForClustering({
    required this.faceID,
    this.clusterId,
    required this.embeddingBytes,
    required this.faceScore,
    required this.blurValue,
    this.isSideways = false,
  });
}
