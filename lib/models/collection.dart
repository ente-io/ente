import 'dart:convert';

class Collection {
  final int id;
  final int ownerID;
  final String encryptedKey;
  final String keyDecryptionNonce;
  final String name;
  final CollectionType type;
  final String encryptedPath;
  final String pathDecryptionNonce;
  final int creationTime;

  Collection(
    this.id,
    this.ownerID,
    this.encryptedKey,
    this.keyDecryptionNonce,
    this.name,
    this.type,
    this.encryptedPath,
    this.pathDecryptionNonce,
    this.creationTime,
  );

  Collection copyWith({
    int id,
    int ownerID,
    String encryptedKey,
    String keyDecryptionNonce,
    String name,
    CollectionType type,
    String encryptedPath,
    String pathDecryptionNonce,
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
      encryptedPath ?? this.pathDecryptionNonce,
      creationTime ?? this.creationTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerID': ownerID,
      'encryptedKey': encryptedKey,
      'keyDecryptionNonce': keyDecryptionNonce,
      'name': name,
      'type': typeToString(type),
      'creationTime': creationTime,
      'encryptedPath': encryptedPath,
      'pathDecryptionNonce': pathDecryptionNonce,
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
      typeFromString(map['type']),
      map['encryptedPath'],
      map['pathDecryptionNonce'],
      map['creationTime'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Collection.fromJson(String source) =>
      Collection.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Collection(id: $id, ownerID: $ownerID, encryptedKey: $encryptedKey, keyDecryptionNonce: $keyDecryptionNonce, name: $name, type: $type, encryptedPath: $encryptedPath, pathDecryptionNonce: $pathDecryptionNonce, creationTime: $creationTime)';
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
        o.pathDecryptionNonce == pathDecryptionNonce &&
        o.creationTime == creationTime;
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
        pathDecryptionNonce.hashCode ^
        creationTime.hashCode;
  }

  static CollectionType typeFromString(String type) {
    switch (type) {
      case "folder":
        return CollectionType.folder;
      case "favorites":
        return CollectionType.favorites;
    }
    return CollectionType.album;
  }

  static String typeToString(CollectionType type) {
    switch (type) {
      case CollectionType.folder:
        return "folder";
      case CollectionType.favorites:
        return "favorites";
      default:
        return "album";
    }
  }
}

enum CollectionType {
  folder,
  favorites,
  album,
}
