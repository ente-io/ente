import 'dart:convert';

class Collection {
  final int id;
  final CollectionOwner owner;
  final String encryptedKey;
  final String keyDecryptionNonce;
  final String name;
  final CollectionType type;
  final CollectionAttributes attributes;
  final int updationTime;
  final bool isDeleted;

  Collection(
    this.id,
    this.owner,
    this.encryptedKey,
    this.keyDecryptionNonce,
    this.name,
    this.type,
    this.attributes,
    this.updationTime, {
    this.isDeleted = false,
  });

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
      'owner': owner?.toMap(),
      'encryptedKey': encryptedKey,
      'keyDecryptionNonce': keyDecryptionNonce,
      'name': name,
      'type': typeToString(type),
      'attributes': attributes?.toMap(),
      'updationTime': updationTime,
    };
  }

  factory Collection.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Collection(
      map['id'],
      CollectionOwner.fromMap(map['owner']),
      map['encryptedKey'],
      map['keyDecryptionNonce'],
      map['name'],
      typeFromString(map['type']),
      CollectionAttributes.fromMap(map['attributes']),
      map['updationTime'],
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Collection.fromJson(String source) =>
      Collection.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Collection(id: $id, owner: ${owner.toString()} encryptedKey: $encryptedKey, keyDecryptionNonce: $keyDecryptionNonce, name: $name, type: $type, attributes: $attributes, creationTime: $updationTime)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Collection &&
        o.id == id &&
        o.owner == owner &&
        o.encryptedKey == encryptedKey &&
        o.keyDecryptionNonce == keyDecryptionNonce &&
        o.name == name &&
        o.type == type &&
        o.attributes == attributes &&
        o.updationTime == updationTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        owner.hashCode ^
        encryptedKey.hashCode ^
        keyDecryptionNonce.hashCode ^
        name.hashCode ^
        type.hashCode ^
        attributes.hashCode ^
        updationTime.hashCode;
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

class CollectionOwner {
  int id;
  String email;
  String name;

  CollectionOwner({
    this.id,
    this.email,
    this.name,
  });

  CollectionOwner copyWith({
    int id,
    String email,
    String name,
  }) {
    return CollectionOwner(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }

  factory CollectionOwner.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return CollectionOwner(
      id: map['id'],
      email: map['email'],
      name: map['name'],
    );
  }

  String toJson() => json.encode(toMap());

  factory CollectionOwner.fromJson(String source) =>
      CollectionOwner.fromMap(json.decode(source));

  @override
  String toString() => 'CollectionOwner(id: $id, email: $email, name: $name)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is CollectionOwner &&
        o.id == id &&
        o.email == email &&
        o.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ name.hashCode;
}
