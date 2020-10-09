import 'dart:convert';

import 'package:flutter/foundation.dart';

class Collection {
  final int id;
  final int ownerID;
  final String encryptedKey;
  final String keyDecryptionNonce;
  final String name;
  final CollectionType type;
  final Map<String, dynamic> attributes;
  final List<String> sharees;

  Collection(
    this.id,
    this.ownerID,
    this.encryptedKey,
    this.keyDecryptionNonce,
    this.name,
    this.type,
    this.attributes,
    this.sharees,
  );

  static Collection emptyCollection() {
    return Collection(null, null, null, null, null, null, null, null);
  }

  Collection copyWith({
    int id,
    int ownerID,
    String encryptedKey,
    String keyDecryptionNonce,
    String name,
    CollectionType type,
    Map<String, dynamic> attributes,
    List<String> sharees,
  }) {
    return Collection(
      id ?? this.id,
      ownerID ?? this.ownerID,
      encryptedKey ?? this.encryptedKey,
      keyDecryptionNonce ?? this.keyDecryptionNonce,
      name ?? this.name,
      type ?? this.type,
      attributes ?? this.attributes,
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
      'attributes': attributes,
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
      Map<String, dynamic>.from(map['attributes']),
      List<String>.from(map['sharees']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Collection.fromJson(String source) =>
      Collection.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Collection(id: $id, ownerID: $ownerID, encryptedKey: $encryptedKey, keyDecryptionNonce: $keyDecryptionNonce, name: $name, type: $type, attributes: $attributes, sharees: $sharees)';
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
        mapEquals(o.attributes, attributes);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ownerID.hashCode ^
        encryptedKey.hashCode ^
        keyDecryptionNonce.hashCode ^
        name.hashCode ^
        type.hashCode ^
        attributes.hashCode;
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
