import 'dart:convert';

import 'package:photos/models/collection.dart';

class SharedCollection {
  final int id;
  final int ownerID;
  final String encryptedKey;
  final String name;
  final CollectionType type;
  final int creationTime;

  SharedCollection(
    this.id,
    this.ownerID,
    this.encryptedKey,
    this.name,
    this.type,
    this.creationTime,
  );

  SharedCollection copyWith({
    int id,
    int ownerID,
    String encryptedKey,
    String name,
    CollectionType type,
    int creationTime,
  }) {
    return SharedCollection(
      id ?? this.id,
      ownerID ?? this.ownerID,
      encryptedKey ?? this.encryptedKey,
      name ?? this.name,
      type ?? this.type,
      creationTime ?? this.creationTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerID': ownerID,
      'encryptedKey': encryptedKey,
      'name': name,
      'type': Collection.typeToString(type),
      'creationTime': creationTime,
    };
  }

  factory SharedCollection.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return SharedCollection(
      map['id'],
      map['ownerID'],
      map['encryptedKey'],
      map['name'],
      Collection.typeFromString(map['type']),
      map['creationTime'],
    );
  }

  String toJson() => json.encode(toMap());

  factory SharedCollection.fromJson(String source) =>
      SharedCollection.fromMap(json.decode(source));

  @override
  String toString() {
    return 'SharedCollection(id: $id, ownerID: $ownerID, encryptedKey: $encryptedKey, name: $name, type: $type, creationTime: $creationTime)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is SharedCollection &&
        o.id == id &&
        o.ownerID == ownerID &&
        o.encryptedKey == encryptedKey &&
        o.name == name &&
        o.type == type &&
        o.creationTime == creationTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ownerID.hashCode ^
        encryptedKey.hashCode ^
        name.hashCode ^
        type.hashCode ^
        creationTime.hashCode;
  }
}
