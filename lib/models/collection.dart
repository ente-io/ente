import 'dart:convert';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:photos/models/magic_metadata.dart';

class Collection {
  final int id;
  final User? owner;
  final String encryptedKey;
  final String? keyDecryptionNonce;
  final String? name;
  final String encryptedName;
  final String nameDecryptionNonce;
  final CollectionType type;
  final CollectionAttributes attributes;
  final List<User?>? sharees;
  final List<PublicURL?>? publicURLs;
  final int updationTime;
  final bool isDeleted;
  String? mMdEncodedJson;
  int mMdVersion = 0;
  CollectionMagicMetadata? _mmd;

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
    return mMdVersion > 0 && magicMetadata.visibility == visibilityArchive;
  }

  bool isHidden() {
    if (isDefaultHidden()) {
      return true;
    }
    return mMdVersion > 0 && (magicMetadata.visibility == visibilityHidden);
  }

  bool isDefaultHidden() {
    return (magicMetadata.subType ?? 0) == subTypeDefaultHidden;
  }

  bool isSharedFilesCollection() {
    return (magicMetadata.subType ?? 0) == subTypeSharedFilesCollection;
  }

  List<User> getSharees() {
    final List<User> result = [];
    if (sharees == null) {
      return result;
    }
    for (final User? u in sharees!) {
      if (u != null) {
        result.add(u);
      }
    }
    return result;
  }

  bool isOwner(int userID) {
    return (owner?.id ?? 0) == userID;
  }

  void updateSharees(List<User> newSharees) {
    sharees?.clear();
    sharees?.addAll(newSharees);
  }

  static CollectionType typeFromString(String type) {
    switch (type) {
      case "folder":
        return CollectionType.folder;
      case "favorites":
        return CollectionType.favorites;
      case "uncategorized":
        return CollectionType.uncategorized;
      case "album":
        return CollectionType.album;
      case "unknown":
        return CollectionType.unknown;
    }
    debugPrint("unexpected collection type $type");
    return CollectionType.unknown;
  }

  static String typeToString(CollectionType type) {
    switch (type) {
      case CollectionType.folder:
        return "folder";
      case CollectionType.favorites:
        return "favorites";
      case CollectionType.album:
        return "album";
      case CollectionType.uncategorized:
        return "uncategorized";
      case CollectionType.unknown:
        return "unknown";
    }
  }

  Collection copyWith({
    int? id,
    User? owner,
    String? encryptedKey,
    String? keyDecryptionNonce,
    String? name,
    String? encryptedName,
    String? nameDecryptionNonce,
    CollectionType? type,
    CollectionAttributes? attributes,
    List<User>? sharees,
    List<PublicURL>? publicURLs,
    int? updationTime,
    bool? isDeleted,
    String? mMdEncodedJson,
    int? mMdVersion,
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
      'attributes': attributes.toMap(),
      'sharees': sharees?.map((x) => x?.toMap()).toList(),
      'publicURLs': publicURLs?.map((x) => x?.toMap()).toList(),
      'updationTime': updationTime,
      'isDeleted': isDeleted,
    };
  }

  static fromMap(Map<String, dynamic>? map) {
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
}

enum CollectionType {
  folder,
  favorites,
  uncategorized,
  album,
  unknown,
}

enum CollectionParticipantRole {
  unknown,
  viewer,
  collaborator,
  owner,
}

extension CollectionParticipantRoleExtn on CollectionParticipantRole {
  static CollectionParticipantRole fromString(String? val) {
    if ((val ?? '') == '') {
      return CollectionParticipantRole.viewer;
    }
    for (var x in CollectionParticipantRole.values) {
      if (x.name.toUpperCase() == val!.toUpperCase()) {
        return x;
      }
    }
    return CollectionParticipantRole.unknown;
  }

  String toStringVal() {
    return name.toUpperCase();
  }
}

class CollectionAttributes {
  final String? encryptedPath;
  final String? pathDecryptionNonce;
  final int? version;

  CollectionAttributes({
    this.encryptedPath,
    this.pathDecryptionNonce,
    this.version,
  });

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

  static fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;

    return CollectionAttributes(
      encryptedPath: map['encryptedPath'],
      pathDecryptionNonce: map['pathDecryptionNonce'],
      version: map['version'] ?? 0,
    );
  }
}

class User {
  int? id;
  String email;
  String? name;
  String? role;

  User({
    this.id,
    required this.email,
    this.name,
    this.role,
  });

  bool get isViewer => role == null || role?.toUpperCase() == 'VIEWER';

  bool get isCollaborator =>
      role != null && role?.toUpperCase() == 'COLLABORATOR';

  Map<String, dynamic> toMap() {
    return {'id': id, 'email': email, 'name': name, 'role': role};
  }

  static fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;

    return User(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      role: map['role'] ?? 'VIEWER',
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));
}

class PublicURL {
  String url;
  int deviceLimit;
  int validTill;
  bool enableDownload;
  bool enableCollect;
  bool passwordEnabled;

  PublicURL({
    required this.url,
    required this.deviceLimit,
    required this.validTill,
    this.enableDownload = true,
    this.passwordEnabled = false,
    this.enableCollect = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'deviceLimit': deviceLimit,
      'validTill': validTill,
      'enableDownload': enableDownload,
      'passwordEnabled': passwordEnabled,
      'enableCollect': enableCollect,
    };
  }

  bool get hasExpiry => validTill != 0;

  // isExpired indicates whether the link has expired or not
  bool get isExpired =>
      hasExpiry && validTill < DateTime.now().microsecondsSinceEpoch;

  static fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;

    return PublicURL(
      url: map['url'],
      deviceLimit: map['deviceLimit'],
      validTill: map['validTill'] ?? 0,
      enableDownload: map['enableDownload'] ?? true,
      passwordEnabled: map['passwordEnabled'] ?? false,
      enableCollect: map['enableCollect'] ?? false,
    );
  }
}
