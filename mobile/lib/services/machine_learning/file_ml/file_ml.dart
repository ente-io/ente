import "package:photos/face/model/face.dart";

class RemoteFileML {
  final int fileID;
  final Map<String, dynamic> remoteRawData;
  final RemoteFaceEmbedding faceEmbedding;
  final RemoteClipEmbedding? clipEmbedding;

  RemoteFileML(
    this.fileID,
    this.remoteRawData, {
    required this.faceEmbedding,
    this.clipEmbedding,
  });

  // toJson
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }

  // fromRemote
  factory RemoteFileML.fromRemote(int fileID, Map<String, dynamic> json) {
    return RemoteFileML(
      fileID,
      json,
      faceEmbedding: RemoteFaceEmbedding.fromJson(
        json['face'] as Map<String, dynamic>,
      ),
      clipEmbedding: json['clip'] == null
          ? null
          : RemoteClipEmbedding.fromJson(
              json['clip'] as Map<String, dynamic>,
            ),
    );
  }
}

class RemoteFaceEmbedding {
  final List<Face> faces;
  final int version;
  // packageName/version
  final String client;
  final int height;
  final int width;

  RemoteFaceEmbedding(
    this.faces,
    this.version, {
    required this.client,
    required this.height,
    required this.width,
  });

  // toJson
  Map<String, dynamic> toJson() => {
        'faces': faces.map((x) => x.toJson()).toList(),
        'version': version,
        'client': client,
        'height': height,
        'width': width,
      };

  // fromJson
  factory RemoteFaceEmbedding.fromJson(Map<String, dynamic> json) {
    return RemoteFaceEmbedding(
      List<Face>.from(
        json['faces'].map((x) => Face.fromJson(x as Map<String, dynamic>)),
      ),
      json['version'] as int,
      client: json['client'] as String,
      height: json['height'] as int,
      width: json['width'] as int,
    );
  }
}

class RemoteClipEmbedding {
  final int version;
  final String client;
  final List<double> embedding;

  RemoteClipEmbedding(
    this.embedding, {
    required this.version,
    required this.client,
  });

  // toJson
  Map<String, dynamic> toJson() => {
        'embedding': embedding,
        'version': version,
        'client': client,
      };

  // fromJson
  factory RemoteClipEmbedding.fromJson(Map<String, dynamic> json) {
    return RemoteClipEmbedding(
      List<double>.from(json['embedding'] as List),
      version: json['version'] as int,
      client: json['client'] as String,
    );
  }
}
