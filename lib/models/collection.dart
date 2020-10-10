import 'dart:convert';

import 'package:flutter/foundation.dart';

class Collection {
  final int id;
  final int ownerID;
  final String encryptedKey;
  final String keyDecryptionNonce;
  final String name;
  final CollectionType type;
  final String encryptedPath;
  final int creationTime;
  final List<String> sharees;

  Collection(
    this.id,
    this.ownerID,
    this.encryptedKey,
    this.keyDecryptionNonce,
    this.name,
    this.type,
    this.encryptedPath,
    this.creationTime,
    this.sharees,
  );

  static Collection emptyCollection() {
    return Collection(null, null, null, null, null, null, null, null, List<String>());
  }

  Collection copyWith({
    int id,
    int ownerID,
    String encryptedKey,
    String keyDecryptionNonce,
    String name,
    CollectionType type,
    String encryptedPath,
    int creationTime,
    List<String> sharees,
  }) {
    return Collection(
      id ?? this.id,
      ownerID ?? this.ownerID,
      encryptedKey ?? this.encryptedKey,
      keyDecryptionNonce ?? this.keyDecryptionNonce,
      name ?? this.name,
      type ?? this.type,
      encryptedPath ?? this.encryptedPath,
      creationTime ?? this.creationTime,
      sharees ?? this.sharees,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerID': ownerID,
      'encryptedKey': encryptedKey,
      'keyDecryptionNonce': keyDecryptionNonce,
      'name': name,
      'type': type.toString(),
      'creationTime': creationTime,
      'encryptedPath': encryptedPath,
      'sharees': sharees,
    };
  }

  factory Collection.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Collection(
      map['id'],
      map['ownerID'],
      map['encryptedKey'],
      map['keyDecryptionNonce'],
      map['name'],
      fromString(map['type']),
      map['encryptedPath'],
      map['creationTime'],
      map['sharees'] == null ? null : List<String>.from(map['sharees']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Collection.fromJson(String source) =>
      Collection.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Collection(id: $id, ownerID: $ownerID, encryptedKey: $encryptedKey, keyDecryptionNonce: $keyDecryptionNonce, name: $name, type: $type, encryptedPath: $encryptedPath, creationTime: $creationTime, sharees: $sharees)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Collection &&
        o.id == id &&
        o.ownerID == ownerID &&
        o.encryptedKey == encryptedKey &&
        o.keyDecryptionNonce == keyDecryptionNonce &&
        o.name == name &&
        o.type == type &&
        o.encryptedPath == encryptedPath &&
        o.creationTime == creationTime &&
        listEquals(o.sharees, sharees);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ownerID.hashCode ^
        encryptedKey.hashCode ^
        keyDecryptionNonce.hashCode ^
        name.hashCode ^
        type.hashCode ^
        encryptedPath.hashCode ^
        creationTime.hashCode ^
        sharees.hashCode;
  }
}

CollectionType fromString(String type) {
  switch (type) {
    case "folder":
      return CollectionType.folder;
    case "favorites":
      return CollectionType.favorites;
  }
  return CollectionType.album;
}

enum CollectionType {
  folder,
  favorites,
  album,
}
