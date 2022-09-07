// @dart=2.9

import 'dart:convert';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:photos/models/magic_metadata.dart';

class Collection {
  final int id;
  final User owner;
  final String encryptedKey;
  final String keyDecryptionNonce;
  final String name;
  final String encryptedName;
  final String nameDecryptionNonce;
  final CollectionType type;
  final CollectionAttributes attributes;
  final List<User> sharees;
  final List<PublicURL> publicURLs;
  final int updationTime;
  final bool isDeleted;
  String mMdEncodedJson;
  int mMdVersion = 0;
  CollectionMagicMetadata _mmd;

  CollectionMagicMetadata get magicMetadata =>
      _mmd ?? CollectionMagicMetadata.fromEncodedJson(mMdEncodedJson ?? '{}');

  set magicMetadata(val) => _mmd = val;

  Collection(
    this.id,
    this.owner,
    this.encryptedKey,
    this.keyDecryptionNonce,
    this.name,
    this.encryptedName,
    this.nameDecryptionNonce,
    this.type,
    this.attributes,
    this.sharees,
    this.publicURLs,
    this.updationTime, {
    this.isDeleted = false,
  });

  bool isArchived() {
    return mMdVersion > 0 && magicMetadata.visibility == kVisibilityArchive;
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

  Collection copyWith({
    int id,
    User owner,
    String encryptedKey,
    String keyDecryptionNonce,
    String name,
    String encryptedName,
    String nameDecryptionNonce,
    CollectionType type,
    CollectionAttributes attributes,
    List<User> sharees,
    List<PublicURL> publicURLs,
    int updationTime,
    bool isDeleted,
    String mMdEncodedJson,
    int mMdVersion,
  }) {
    final Collection result = Collection(
      id ?? this.id,
      owner ?? this.owner,
      encryptedKey ?? this.encryptedKey,
      keyDecryptionNonce ?? this.keyDecryptionNonce,
      name ?? this.name,
      encryptedName ?? this.encryptedName,
      nameDecryptionNonce ?? this.nameDecryptionNonce,
      type ?? this.type,
      attributes ?? this.attributes,
      sharees ?? this.sharees,
      publicURLs ?? this.publicURLs,
      updationTime ?? this.updationTime,
      isDeleted: isDeleted ?? this.isDeleted,
    );
    result.mMdVersion = mMdVersion ?? this.mMdVersion;
    result.mMdEncodedJson = mMdEncodedJson ?? this.mMdEncodedJson;
    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner': owner?.toMap(),
      'encryptedKey': encryptedKey,
      'keyDecryptionNonce': keyDecryptionNonce,
      'name': name,
      'encryptedName': encryptedName,
      'nameDecryptionNonce': nameDecryptionNonce,
      'type': typeToString(type),
      'attributes': attributes?.toMap(),
      'sharees': sharees?.map((x) => x?.toMap())?.toList(),
      'publicURLs': publicURLs?.map((x) => x?.toMap())?.toList(),
      'updationTime': updationTime,
      'isDeleted': isDeleted,
    };
  }

  factory Collection.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;
    final sharees = (map['sharees'] == null || map['sharees'].length == 0)
        ? <User>[]
        : List<User>.from(map['sharees'].map((x) => User.fromMap(x)));
    final publicURLs =
        (map['publicURLs'] == null || map['publicURLs'].length == 0)
            ? <PublicURL>[]
            : List<PublicURL>.from(
                map['publicURLs'].map((x) => PublicURL.fromMap(x)),
              );
    return Collection(
      map['id'],
      User.fromMap(map['owner']),
      map['encryptedKey'],
      map['keyDecryptionNonce'],
      map['name'],
      map['encryptedName'],
      map['nameDecryptionNonce'],
      typeFromString(map['type']),
      CollectionAttributes.fromMap(map['attributes']),
      sharees,
      publicURLs,
      map['updationTime'],
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Collection.fromJson(String source) =>
      Collection.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Collection(id: $id, owner: $owner, encryptedKey: $encryptedKey, keyDecryptionNonce: $keyDecryptionNonce, name: $name, encryptedName: $encryptedName, nameDecryptionNonce: $nameDecryptionNonce, type: $type, attributes: $attributes, sharees: $sharees, publicURLs: $publicURLs, updationTime: $updationTime, isDeleted: $isDeleted)';
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
        o.encryptedName == encryptedName &&
        o.nameDecryptionNonce == nameDecryptionNonce &&
        o.type == type &&
        o.attributes == attributes &&
        listEquals(o.sharees, sharees) &&
        listEquals(o.publicURLs, publicURLs) &&
        o.updationTime == updationTime &&
        o.isDeleted == isDeleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        owner.hashCode ^
        encryptedKey.hashCode ^
        keyDecryptionNonce.hashCode ^
        name.hashCode ^
        encryptedName.hashCode ^
        nameDecryptionNonce.hashCode ^
        type.hashCode ^
        attributes.hashCode ^
        sharees.hashCode ^
        publicURLs.hashCode ^
        updationTime.hashCode ^
        isDeleted.hashCode;
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
  final int version;

  CollectionAttributes({
    this.encryptedPath,
    this.pathDecryptionNonce,
    this.version,
  });

  CollectionAttributes copyWith({
    String encryptedPath,
    String pathDecryptionNonce,
    int version,
  }) {
    return CollectionAttributes(
      encryptedPath: encryptedPath ?? this.encryptedPath,
      pathDecryptionNonce: pathDecryptionNonce ?? this.pathDecryptionNonce,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (encryptedPath != null) {
      map['encryptedPath'] = encryptedPath;
    }
    if (pathDecryptionNonce != null) {
      map['pathDecryptionNonce'] = pathDecryptionNonce;
    }
    map['version'] = version ?? 0;
    return map;
  }

  factory CollectionAttributes.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return CollectionAttributes(
      encryptedPath: map['encryptedPath'],
      pathDecryptionNonce: map['pathDecryptionNonce'],
      version: map['version'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory CollectionAttributes.fromJson(String source) =>
      CollectionAttributes.fromMap(json.decode(source));

  @override
  String toString() =>
      'CollectionAttributes(encryptedPath: $encryptedPath, pathDecryptionNonce: $pathDecryptionNonce, version: $version)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is CollectionAttributes &&
        o.encryptedPath == encryptedPath &&
        o.pathDecryptionNonce == pathDecryptionNonce &&
        o.version == version;
  }

  @override
  int get hashCode =>
      encryptedPath.hashCode ^ pathDecryptionNonce.hashCode ^ version.hashCode;
}

class User {
  int id;
  String email;
  String name;

  User({
    this.id,
    this.email,
    this.name,
  });

  User copyWith({
    int id,
    String email,
    String name,
  }) {
    return User(
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

  factory User.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return User(
      id: map['id'],
      email: map['email'],
      name: map['name'],
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  @override
  String toString() => 'CollectionOwner(id: $id, email: $email, name: $name)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is User && o.id == id && o.email == email && o.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ name.hashCode;
}

class PublicURL {
  String url;
  int deviceLimit;
  int validTill;
  bool enableDownload = true;
  bool passwordEnabled = false;

  PublicURL({
    this.url,
    this.deviceLimit,
    this.validTill,
    this.enableDownload,
    this.passwordEnabled,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'deviceLimit': deviceLimit,
      'validTill': validTill,
      'enableDownload': enableDownload,
      'passwordEnabled': passwordEnabled,
    };
  }

  factory PublicURL.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return PublicURL(
      url: map['url'],
      deviceLimit: map['deviceLimit'],
      validTill: map['validTill'] ?? 0,
      enableDownload: map['enableDownload'] ?? true,
      passwordEnabled: map['passwordEnabled'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory PublicURL.fromJson(String source) =>
      PublicURL.fromMap(json.decode(source));

  @override
  String toString() =>
      'PublicUrl( url: $url, deviceLimit: $deviceLimit, validTill: $validTill, , enableDownload: $enableDownload, , passwordEnabled: $passwordEnabled)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is PublicURL &&
        o.deviceLimit == deviceLimit &&
        o.url == url &&
        o.validTill == validTill &&
        o.enableDownload == enableDownload &&
        o.passwordEnabled == passwordEnabled;
  }

  @override
  int get hashCode =>
      deviceLimit.hashCode ^
      url.hashCode ^
      validTill.hashCode ^
      enableDownload.hashCode ^
      passwordEnabled.hashCode;
}
