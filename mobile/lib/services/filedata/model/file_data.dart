import "package:photos/models/ml/face/face.dart";

const _faceKey = 'face';
const _clipKey = 'clip';

enum DataType {
  mlData('mldata');

  final String value;
  const DataType(this.value);

  static DataType fromString(String type) {
    return DataType.values.firstWhere(
      (e) => e.value == type,
      orElse: () {
        throw Exception('Unknown type: $type');
      },
    );
  }

  String toJson() => value;
  static DataType fromJson(String json) => DataType.fromString(json);
}

class FileDataEntity {
  final int fileID;
  final Map<String, dynamic> remoteRawData;
  final DataType type;

  FileDataEntity(
    this.fileID,
    this.remoteRawData,
    this.type,
  );

  void validate() {
    if (type == DataType.mlData) {
      if (remoteRawData[_faceKey] == null) {
        throw Exception('Face embedding is null');
      }
      if (remoteRawData[_clipKey] == null) {
        throw Exception('Clip embedding is null');
      }
    } else {
      throw Exception('Invalid type ${type.value}');
    }
  }

  factory FileDataEntity.fromRemote(
    int fileID,
    String type,
    Map<String, dynamic> json,
  ) {
    return FileDataEntity(
      fileID,
      json,
      DataType.fromString(type),
    );
  }

  static FileDataEntity empty(int fileID, DataType type) {
    final Map<String, dynamic> json = {};
    return FileDataEntity(fileID, json, type);
  }

  void putFace(RemoteFaceEmbedding faceEmbedding) {
    assert(type == DataType.mlData, 'Invalid type ${type.value}');
    remoteRawData[_faceKey] = faceEmbedding.toJson();
  }

  void putClip(RemoteClipEmbedding clipEmbedding) {
    assert(type == DataType.mlData, 'Invalid type ${type.value}');
    remoteRawData[_clipKey] = clipEmbedding.toJson();
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
      parseAsDoubleList(json['embedding'] as List),
      version: json['version'] as int,
      client: json['client'] as String,
    );
  }
}
