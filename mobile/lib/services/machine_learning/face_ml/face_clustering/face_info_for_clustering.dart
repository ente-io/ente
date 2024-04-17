
import "dart:typed_data" show Uint8List;

class FaceInfoForClustering {
  final String faceID;
  final int? clusterId;
  final Uint8List embeddingBytes;
  final double faceScore;
  final double blurValue;

  FaceInfoForClustering({
    required this.faceID,
    this.clusterId,
    required this.embeddingBytes,
    required this.faceScore,
    required this.blurValue,
  });
}