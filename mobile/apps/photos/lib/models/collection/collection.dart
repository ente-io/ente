import "dart:convert";
import 'dart:core';

import 'package:flutter/foundation.dart';
import "package:photos/core/configuration.dart";
import "package:photos/extensions/user_extension.dart";
import "package:photos/models/api/collection/public_url.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/collection/collection_old.dart";
import "package:photos/models/metadata/collection_magic.dart";
import "package:photos/models/metadata/common_keys.dart";

class Collection {
  final int id;
  final User owner;
  final String encryptedKey;
  // keyDecryptionNonce will be empty string for collections shared with the user
  final String keyDecryptionNonce;
  String? name;
  final CollectionType type;
  final List<User> sharees;
  final List<PublicURL> publicURLs;
  final int updationTime;
  final bool isDeleted;
  final String? localPath;
  String mMdEncodedJson;
  String mMdPubEncodedJson;
  String sharedMmdJson;
  int mMdVersion = 0;
  int mMbPubVersion = 0;
  int sharedMmdVersion = 0;
  CollectionMagicMetadata? _mmd;
  CollectionPubMagicMetadata? _pubMmd;
  ShareeMagicMetadata? _sharedMmd;

  CollectionMagicMetadata get magicMetadata =>
      _mmd ?? CollectionMagicMetadata.fromEncodedJson(mMdEncodedJson);

  CollectionPubMagicMetadata get pubMagicMetadata =>
      _pubMmd ?? CollectionPubMagicMetadata.fromEncodedJson(mMdPubEncodedJson);

  ShareeMagicMetadata get sharedMagicMetadata =>
      _sharedMmd ?? ShareeMagicMetadata.fromEncodedJson(sharedMmdJson);

  set magicMetadata(CollectionMagicMetadata? val) => _mmd = val;

  set pubMagicMetadata(CollectionPubMagicMetadata? val) => _pubMmd = val;

  set sharedMagicMetadata(ShareeMagicMetadata? val) => _sharedMmd = val;

  // ignore: deprecated_member_use_from_same_package
  String get displayName {
    if (!isDeleted &&
        type == CollectionType.favorites &&
        !isOwner(Configuration.instance.getUserID() ?? -1)) {
      return '${owner.nameOrEmail}\'s favorites';
    }
    return name ?? "Unnamed Album";
  }

  void setName(String newName) {
    // ignore: deprecated_member_use_from_same_package
    name = newName;
  }

  Collection({
    required this.id,
    required this.owner,
    required this.encryptedKey,
    required this.keyDecryptionNonce,
    required this.name,
    required this.type,
    required this.sharees,
    required this.publicURLs,
    required this.updationTime,
    required this.localPath,
    this.isDeleted = false,
    this.mMdEncodedJson = '{}',
    this.mMdPubEncodedJson = '{}',
    this.sharedMmdJson = '{}',
    this.mMdVersion = 0,
    this.mMbPubVersion = 0,
    this.sharedMmdVersion = 0,
  });

  factory Collection.fromOldCollection(CollectionV2 collection) {
    return Collection(
      id: collection.id,
      owner: collection.owner,
      encryptedKey: collection.encryptedKey,
      // note: keyDecryptionNonce will be null in case of collections
      // shared with the user
      keyDecryptionNonce: collection.keyDecryptionNonce ?? '',
      name: collection.displayName,
      type: collection.type,
      sharees: collection.sharees,
      publicURLs: collection.publicURLs,
      updationTime: collection.updationTime,
      localPath: collection.decryptedPath,
      isDeleted: collection.isDeleted,
      mMbPubVersion: collection.mMbPubVersion,
      mMdPubEncodedJson: collection.mMdPubEncodedJson ?? '{}',
      mMdVersion: collection.mMdVersion,
      mMdEncodedJson: collection.mMdEncodedJson ?? '{}',
      sharedMmdJson: collection.sharedMmdJson ?? '{}',
      sharedMmdVersion: collection.sharedMmdVersion,
    );
  }

  bool isArchived() {
    return mMdVersion > 0 && magicMetadata.visibility == archiveVisibility;
  }

  bool hasShareeArchived() {
    return sharedMmdVersion > 0 &&
        sharedMagicMetadata.visibility == archiveVisibility;
  }

  // hasLink returns true if there's any link attached to the collection
  // including expired links
  bool get hasLink => publicURLs.isNotEmpty;

  bool get hasCover => (pubMagicMetadata.coverID ?? 0) > 0;

  // hasSharees returns true if the collection is shared with other ente users
  bool get hasSharees => sharees.isNotEmpty;

  bool get isPinned => (magicMetadata.order ?? 0) != 0;

  bool isHidden() {
    if (isDefaultHidden()) {
      return true;
    }
    return mMdVersion > 0 && (magicMetadata.visibility == hiddenVisibility);
  }

  int get visibility {
    if (isHidden()) {
      return hiddenVisibility;
    } else if (isArchived() || hasShareeArchived()) {
      return archiveVisibility;
    }
    return 0;
  }

  bool isDefaultHidden() {
    return (magicMetadata.subType ?? 0) == subTypeDefaultHidden;
  }

  bool isQuickLinkCollection() {
    return (magicMetadata.subType ?? 0) == subTypeSharedFilesCollection &&
        !hasSharees;
  }

  List<User> getSharees() {
    return sharees;
  }

  bool isOwner(int userID) {
    return (owner.id ?? -100) == userID;
  }

  bool canAutoAdd(int userID) {
    final canEditCollection = isOwner(userID) ||
        getRole(userID) == CollectionParticipantRole.collaborator;
    final isFavoritesOrUncategorized = type == CollectionType.favorites ||
        type == CollectionType.uncategorized;
    return canEditCollection && !isDeleted && !isFavoritesOrUncategorized;
  }

  bool isDownloadEnabledForPublicLink() {
    if (publicURLs.isEmpty) {
      return false;
    }
    return publicURLs.first.enableDownload;
  }

  bool isCollectEnabledForPublicLink() {
    if (publicURLs.isEmpty) {
      return false;
    }
    return publicURLs.first.enableCollect;
  }

  bool get isJoinEnabled {
    if (publicURLs.isEmpty) {
      return false;
    }
    return publicURLs.first.enableJoin;
  }

  CollectionParticipantRole getRole(int userID) {
    if (isOwner(userID)) {
      return CollectionParticipantRole.owner;
    }
    if (sharees.isEmpty) {
      return CollectionParticipantRole.unknown;
    }
    for (final User u in sharees) {
      if (u.id == userID) {
        if (u.isViewer) {
          return CollectionParticipantRole.viewer;
        } else if (u.isCollaborator) {
          return CollectionParticipantRole.collaborator;
        }
      }
    }
    return CollectionParticipantRole.unknown;
  }

  // canLinkToDevicePath returns true if the collection can be linked to local
  // device album based on path. The path is nothing but the name of the device
  // album.
  bool canLinkToDevicePath(int userID) {
    return isOwner(userID) &&
        !isDeleted &&
        localPath != null &&
        localPath != '';
  }

  void updateSharees(List<User> newSharees) {
    sharees.clear();
    sharees.addAll(newSharees);
  }

  Collection copyWith({
    int? id,
    User? owner,
    String? encryptedKey,
    String? keyDecryptionNonce,
    String? name,
    CollectionType? type,
    List<User>? sharees,
    List<PublicURL>? publicURLs,
    int? updationTime,
    bool? isDeleted,
    String? localPath,
    String? mMdEncodedJson,
    int? mMdVersion,
    String? mMdPubEncodedJson,
    int? mMbPubVersion,
    String? sharedMmdJson,
    int? sharedMmdVersion,
  }) {
    final Collection result = Collection(
      id: id ?? this.id,
      owner: owner ?? this.owner,
      encryptedKey: encryptedKey ?? this.encryptedKey,
      keyDecryptionNonce: keyDecryptionNonce ?? this.keyDecryptionNonce,
      name: name ?? this.name,
      type: type ?? this.type,
      sharees: sharees ?? this.sharees,
      publicURLs: publicURLs ?? this.publicURLs,
      updationTime: updationTime ?? this.updationTime,
      localPath: localPath ?? this.localPath,
      isDeleted: isDeleted ?? this.isDeleted,
      mMdEncodedJson: mMdEncodedJson ?? this.mMdEncodedJson,
      mMdVersion: mMdVersion ?? this.mMdVersion,
      mMdPubEncodedJson: mMdPubEncodedJson ?? this.mMdPubEncodedJson,
      mMbPubVersion: mMbPubVersion ?? this.mMbPubVersion,
      sharedMmdJson: sharedMmdJson ?? this.sharedMmdJson,
      sharedMmdVersion: sharedMmdVersion ?? this.sharedMmdVersion,
    );
    return result;
  }

  static Collection fromRow(Map<String, dynamic> map) {
    final sharees = List<User>.from(
      (json.decode(map['sharees']) as List).map((x) => User.fromMap(x)),
    );
    final List<PublicURL> publicURLs = List<PublicURL>.from(
      (json.decode(map['public_urls']) as List)
          .map((x) => PublicURL.fromMap(x)),
    );
    return Collection(
      id: map['id'],
      owner: User.fromJson(map['owner']),
      encryptedKey: map['enc_key'],
      keyDecryptionNonce: map['enc_key_nonce'],
      name: map['name'],
      type: typeFromString(map['type']),
      sharees: sharees,
      publicURLs: publicURLs,
      updationTime: map['updation_time'],
      localPath: map['local_path'],
      isDeleted: (map['is_deleted'] as int) == 1,
      mMdEncodedJson: map['mmd_encoded_json'],
      mMdVersion: map['mmd_ver'],
      mMdPubEncodedJson: map['pub_mmd_encoded_json'],
      mMbPubVersion: map['pub_mmd_ver'],
      sharedMmdJson: map['shared_mmd_json'],
      sharedMmdVersion: map['shared_mmd_ver'],
    );
  }

  List<Object?> rowValiues() {
    return [
      id,
      owner.toJson(),
      encryptedKey,
      keyDecryptionNonce,
      name,
      typeToString(type),
      localPath,
      isDeleted ? 1 : 0,
      updationTime,
      json.encode(sharees.map((x) => x.toMap()).toList()),
      json.encode(publicURLs.map((x) => x.toMap()).toList()),
      mMdEncodedJson,
      mMdVersion,
      mMdPubEncodedJson,
      mMbPubVersion,
      sharedMmdJson,
      sharedMmdVersion,
    ];
  }
}

enum CollectionType {
  folder,
  favorites,
  uncategorized,
  album,
  unknown,
}

CollectionType typeFromString(String type) {
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

String typeToString(CollectionType type) {
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

extension CollectionTypeExtn on CollectionType {
  bool get canDelete =>
      this != CollectionType.favorites && this != CollectionType.uncategorized;
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
