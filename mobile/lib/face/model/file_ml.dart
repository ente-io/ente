import "package:photos/face/model/face.dart";

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
  final String framwork;
  final List<double> embedding;
  ClipEmbedding(this.embedding, this.framwork, {this.version});
  // toJson
  Map<String, dynamic> toJson() => {
        'version': version,
        'framwork': framwork,
        'embedding': embedding,
      };
  // fromJson
  factory ClipEmbedding.fromJson(Map<String, dynamic> json) {
    return ClipEmbedding(
      List<double>.from(json['embedding'] as List),
      json['framwork'] as String,
      version: json['version'] as int?,
    );
  }
}

class FileMl {
  final int fileID;
  final FaceEmbeddings face;
  final ClipEmbedding? clip;
  final String? last4Hash;

  FileMl(this.fileID, this.face, {this.clip, this.last4Hash});

  // toJson
  Map<String, dynamic> toJson() => {
        'fileID': fileID,
        'face': face.toJson(),
        'clip': clip?.toJson(),
        'last4Hash': last4Hash,
      };
  // fromJson
  factory FileMl.fromJson(Map<String, dynamic> json) {
    return FileMl(
      json['fileID'] as int,
      FaceEmbeddings.fromJson(json['face'] as Map<String, dynamic>),
      clip: json['clip'] == null
          ? null
          : ClipEmbedding.fromJson(json['clip'] as Map<String, dynamic>),
      last4Hash: json['last4Hash'] as String?,
    );
  }
}
