import "dart:typed_data" show Uint8List;

class FaceDbInfoForClustering<T> {
  final String faceID;
  String? clusterId;
  List<String>? rejectedClusterIds;
  final Uint8List embeddingBytes;
  final double faceScore;
  final double blurValue;
  final bool isSideways;
  T? _fileID;

  T get fileID {
    if (_fileID != null) {
      return _fileID!;
    }
    if (T == String) {
      _fileID = faceID.split('_').first as T;
    }
    if (T == int) {
      _fileID = int.parse(faceID.split('_').first) as T;
    }

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
