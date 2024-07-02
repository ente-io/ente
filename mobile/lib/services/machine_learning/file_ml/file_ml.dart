import "package:photos/face/model/face.dart";

class FileMl {
  final int fileID;
  final int? height;
  final int? width;
  final FaceEmbeddings faceEmbedding;

  FileMl(
    this.fileID,
    this.faceEmbedding, {
    this.height,
    this.width,
  });

  // toJson
  Map<String, dynamic> toJson() => {
        'fileID': fileID,
        'height': height,
        'width': width,
        'faceEmbedding': faceEmbedding.toJson(),
      };
  // fromJson
  factory FileMl.fromJson(Map<String, dynamic> json) {
    return FileMl(
      json['fileID'] as int,
      FaceEmbeddings.fromJson(json['faceEmbedding'] as Map<String, dynamic>),
      height: json['height'] as int?,
      width: json['width'] as int?,
    );
  }
}

class FaceEmbeddings {
  final List<Face> faces;
  final int version;
  // pkgname/version
  final String client;

  FaceEmbeddings(
    this.faces,
    this.version, {
    required this.client,
  });

  // toJson
  Map<String, dynamic> toJson() => {
        'faces': faces.map((x) => x.toJson()).toList(),
        'version': version,
        'client': client,
      };
  // fromJson
  factory FaceEmbeddings.fromJson(Map<String, dynamic> json) {
    return FaceEmbeddings(
      List<Face>.from(
        json['faces'].map((x) => Face.fromJson(x as Map<String, dynamic>)),
      ),
      json['version'] as int,
      client: json['client'] ?? 'unknown',
    );
  }
}

class ClipEmbedding {
  final int? version;
  final List<double> embedding;
  ClipEmbedding(this.embedding, {this.version});
  // toJson
  Map<String, dynamic> toJson() => {
        'version': version,
        'embedding': embedding,
      };
  // fromJson
  factory ClipEmbedding.fromJson(Map<String, dynamic> json) {
    return ClipEmbedding(
      List<double>.from(json['embedding'] as List),
      version: json['version'] as int?,
    );
  }
}
