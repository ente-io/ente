import "dart:typed_data" show Uint8List;

class FaceDbInfoForClustering {
  final String faceID;
  int? clusterId;
  final Uint8List embeddingBytes;
  final double faceScore;
  final double blurValue;
  final bool isSideways;
  int? _fileID;

  int get fileID {
    _fileID ??= int.parse(faceID.split('_').first);
    return _fileID!;
  }

  FaceDbInfoForClustering({
    required this.faceID,
    this.clusterId,
    required this.embeddingBytes,
    required this.faceScore,
    required this.blurValue,
    this.isSideways = false,
  });
}
