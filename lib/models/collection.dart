import 'dart:convert';

class Collection {
  final int id;
  final int ownerID;
  final String ownerEmail;
  final String encryptedKey;
  final String keyDecryptionNonce;
  final String name;
  final CollectionType type;
  final CollectionAttributes attributes;
  final int creationTime;

  Collection(
    this.id,
    this.ownerID,
    this.ownerEmail,
    this.encryptedKey,
    this.keyDecryptionNonce,
    this.name,
    this.type,
    this.attributes,
    this.creationTime,
  );

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerID': ownerID,
      'encryptedKey': encryptedKey,
      'keyDecryptionNonce': keyDecryptionNonce,
      'name': name,
      'type': typeToString(type),
      'attributes': attributes?.toMap(),
      'creationTime': creationTime,
    };
  }

  factory Collection.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Collection(
      map['id'],
      map['ownerID'],
      map['ownerEmail'],
      map['encryptedKey'],
      map['keyDecryptionNonce'],
      map['name'],
      typeFromString(map['type']),
      CollectionAttributes.fromMap(map['attributes']),
      map['creationTime'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Collection.fromJson(String source) =>
      Collection.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Collection(id: $id, ownerID: $ownerID, ownerEmail: $ownerEmail, encryptedKey: $encryptedKey, keyDecryptionNonce: $keyDecryptionNonce, name: $name, type: $type, attributes: $attributes, creationTime: $creationTime)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Collection &&
        o.id == id &&
        o.ownerID == ownerID &&
        o.ownerEmail == ownerEmail &&
        o.encryptedKey == encryptedKey &&
        o.keyDecryptionNonce == keyDecryptionNonce &&
        o.name == name &&
        o.type == type &&
        o.attributes == attributes &&
        o.creationTime == creationTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ownerID.hashCode ^
        ownerEmail.hashCode ^
        encryptedKey.hashCode ^
        keyDecryptionNonce.hashCode ^
        name.hashCode ^
        type.hashCode ^
        attributes.hashCode ^
        creationTime.hashCode;
  }
}

enum CollectionType {
  folder,
  favorites,
  album,
}

class CollectionAttributes {
  final String encryptedPath;
  final String pathDecryptionNonce;

  CollectionAttributes({
    this.encryptedPath,
    this.pathDecryptionNonce,
  });

  CollectionAttributes copyWith({
    String encryptedPath,
    String pathDecryptionNonce,
  }) {
    return CollectionAttributes(
      encryptedPath: encryptedPath ?? this.encryptedPath,
      pathDecryptionNonce: pathDecryptionNonce ?? this.pathDecryptionNonce,
    );
  }

  Map<String, dynamic> toMap() {
    final map = Map<String, dynamic>();
    if (encryptedPath != null) {
      map['encryptedPath'] = encryptedPath;
    }
    if (pathDecryptionNonce != null) {
      map['pathDecryptionNonce'] = pathDecryptionNonce;
    }
    return map;
  }

  factory CollectionAttributes.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return CollectionAttributes(
      encryptedPath: map['encryptedPath'],
      pathDecryptionNonce: map['pathDecryptionNonce'],
    );
  }

  String toJson() => json.encode(toMap());

  factory CollectionAttributes.fromJson(String source) =>
      CollectionAttributes.fromMap(json.decode(source));

  @override
  String toString() =>
      'CollectionAttributes(encryptedPath: $encryptedPath, pathDecryptionNonce: $pathDecryptionNonce)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is CollectionAttributes &&
        o.encryptedPath == encryptedPath &&
        o.pathDecryptionNonce == pathDecryptionNonce;
  }

  @override
  int get hashCode => encryptedPath.hashCode ^ pathDecryptionNonce.hashCode;
}
