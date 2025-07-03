import "package:photos/models/file/file_type.dart";

class SharedAsset {
  final String id;
  final String name;
  final FileType type;
  final int creationTime;
  final int durationInSeconds;
  final int destCollectionID;
  final int ownerID;
  final int? latitude;
  final int? longitude;

  SharedAsset({
    required this.id,
    required this.name,
    required this.type,
    required this.creationTime,
    required this.durationInSeconds,
    required this.destCollectionID,
    required this.ownerID,
    this.latitude,
    this.longitude,
  });

  List<Object?> get rowProps => [
        id,
        name,
        getInt(type),
        creationTime,
        durationInSeconds,
        destCollectionID,
        ownerID,
        latitude,
        longitude,
      ];

  factory SharedAsset.fromRow(Map<String, dynamic> map) {
    return SharedAsset(
      id: map['id'] as String,
      name: map['name'] as String,
      type: getFileType(['type'] as int),
      creationTime: map['creation_time'] as int,
      durationInSeconds: map['duration_in_seconds'] as int,
      destCollectionID: map['dest_collection_id'] as int,
      ownerID: map['owner_id'] as int,
      latitude: map['latitude'] as int?,
      longitude: map['longitude'] as int?,
    );
  }
}
