import "package:photos/face/model/face.dart";

const _faceKey = 'face';
const _clipKey = 'clip';

class FileDataEntity {
  final int fileID;
  final Map<String, dynamic> remoteRawData;

  FileDataEntity(
    this.fileID,
    this.remoteRawData,
  );

  void putSanityCheck() {
    if (remoteRawData[_faceKey] == null) {
      throw Exception('Face embedding is null');
    }
    if (remoteRawData[_clipKey] == null) {
      throw Exception('Clip embedding is null');
    }
  }

  factory FileDataEntity.fromRemote(
    int fileID,
    Map<String, dynamic> json,
  ) {
    return FileDataEntity(
      fileID,
      json,
    );
  }

  static FileDataEntity empty(int i) {
    final Map<String, dynamic> json = {};
    return FileDataEntity(i, json);
  }

  void putFaceIfNotNull(RemoteFaceEmbedding? faceEmbedding) {
    if (faceEmbedding != null) {
      remoteRawData[_faceKey] = faceEmbedding.toJson();
    }
  }

  void putClipIfNotNull(RemoteClipEmbedding? clipEmbedding) {
    if (clipEmbedding != null) {
      remoteRawData[_clipKey] = clipEmbedding.toJson();
    }
  }

  RemoteFaceEmbedding? get faceEmbedding => remoteRawData[_faceKey] != null
      ? RemoteFaceEmbedding.fromJson(
          remoteRawData[_faceKey] as Map<String, dynamic>,
        )
      : null;

  RemoteClipEmbedding? get clipEmbedding => remoteRawData[_clipKey] != null
      ? RemoteClipEmbedding.fromJson(
          remoteRawData[_clipKey] as Map<String, dynamic>,
        )
      : null;
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
