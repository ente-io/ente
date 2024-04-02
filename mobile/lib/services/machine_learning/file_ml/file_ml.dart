import "package:photos/face/model/face.dart";

class FileMl {
  final int fileID;
  final int? height;
  final int? width;
  // json: face
  final FaceEmbeddings faceEmbedding;
  final ClipEmbedding? clipEmbedding;
  // int updationTime that is not serialized
  int? updationTime;

  FileMl(
    this.fileID,
    this.faceEmbedding, {
    this.height,
    this.width,
    this.clipEmbedding,
  });

  // toJson
  Map<String, dynamic> toJson() => {
        'fileID': fileID,
        'height': height,
        'width': width,
        'faceEmbedding': faceEmbedding.toJson(),
        'clipEmbedding': clipEmbedding?.toJson(),
      };
  // fromJson
  factory FileMl.fromJson(Map<String, dynamic> json) {
    return FileMl(
      json['fileID'] as int,
      FaceEmbeddings.fromJson(json['faceEmbedding'] as Map<String, dynamic>),
      height: json['height'] as int?,
      width: json['width'] as int?,
      clipEmbedding: json['clipEmbedding'] == null
          ? null
          : ClipEmbedding.fromJson(
              json['clipEmbedding'] as Map<String, dynamic>,
            ),
    );
  }
}

class FaceEmbeddings {
  final List<Face> faces;
  final int version;
  // Platform: appVersion
  final String? client;
  final bool? error;

  FaceEmbeddings(
    this.faces,
    this.version, {
    this.client,
    this.error,
  });

  // toJson
  Map<String, dynamic> toJson() => {
        'faces': faces.map((x) => x.toJson()).toList(),
        'version': version,
        'client': client,
        'error': error,
      };
  // fromJson
  factory FaceEmbeddings.fromJson(Map<String, dynamic> json) {
    return FaceEmbeddings(
      List<Face>.from(
        json['faces'].map((x) => Face.fromJson(x as Map<String, dynamic>)),
      ),
      json['version'] as int,
      client: json['client'] as String?,
      error: json['error'] as bool?,
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
