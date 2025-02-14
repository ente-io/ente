import "package:photos/models/api/collection/public_url.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/metadata/collection_magic.dart";
import "package:photos/models/metadata/common_keys.dart";

class CollectionV2 {
  final int id;
  final User owner;
  final String encryptedKey;
  final String? keyDecryptionNonce;
  @Deprecated("Use collectionName instead")
  String? name;

  // encryptedName & nameDecryptionNonce will be null for collections
  // created before we started encrypting collection name
  final String? encryptedName;
  final String? nameDecryptionNonce;
  final CollectionType type;
  final CollectionAttributes attributes;
  final List<User> sharees;
  final List<PublicURL> publicURLs;
  final int updationTime;
  final bool isDeleted;

  // In early days before public launch, we used to store collection name
  // un-encrypted. decryptName will be value either decrypted value for
  // encryptedName or name itself.
  String? decryptedName;

  // decryptedPath will be null for collections now owned by user, deleted
  // collections, && collections which don't have a path. The path is used
  // to map local on-device album on mobile to remote collection on ente.
  String? decryptedPath;
  String? mMdEncodedJson;
  String? mMdPubEncodedJson;
  String? sharedMmdJson;
  int mMdVersion = 0;
  int mMbPubVersion = 0;
  int sharedMmdVersion = 0;
  CollectionMagicMetadata? _mmd;
  CollectionPubMagicMetadata? _pubMmd;
  ShareeMagicMetadata? _sharedMmd;

  CollectionMagicMetadata get magicMetadata =>
      _mmd ?? CollectionMagicMetadata.fromEncodedJson(mMdEncodedJson ?? '{}');

  CollectionPubMagicMetadata get pubMagicMetadata =>
      _pubMmd ??
      CollectionPubMagicMetadata.fromEncodedJson(mMdPubEncodedJson ?? '{}');

  ShareeMagicMetadata get sharedMagicMetadata =>
      _sharedMmd ?? ShareeMagicMetadata.fromEncodedJson(sharedMmdJson ?? '{}');

  set magicMetadata(CollectionMagicMetadata? val) => _mmd = val;

  set pubMagicMetadata(CollectionPubMagicMetadata? val) => _pubMmd = val;

  set sharedMagicMetadata(ShareeMagicMetadata? val) => _sharedMmd = val;

  String get displayName => decryptedName ?? name ?? "Unnamed Album";

  // set the value for both name and decryptedName till we finish migration
  void setName(String newName) {
    name = newName;
    decryptedName = newName;
  }

  CollectionV2(
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
    return isOwner(userID) && !isDeleted && attributes.encryptedPath != null;
  }

  void updateSharees(List<User> newSharees) {
    sharees.clear();
    sharees.addAll(newSharees);
  }

  CollectionV2 copyWith({
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
    String? decryptedName,
    String? decryptedPath,
  }) {
    final CollectionV2 result = CollectionV2(
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
    result.decryptedName = decryptedName ?? this.decryptedName;
    result.decryptedPath = decryptedPath ?? this.decryptedPath;
    result.mMbPubVersion = mMbPubVersion;
    result.mMdPubEncodedJson = mMdPubEncodedJson;
    result.sharedMmdVersion = sharedMmdVersion;
    result.sharedMmdJson = sharedMmdJson;
    return result;
  }

  static CollectionV2 fromMap(Map<String, dynamic> map) {
    final sharees = (map['sharees'] == null || map['sharees'].length == 0)
        ? <User>[]
        : List<User>.from(map['sharees'].map((x) => User.fromMap(x)));
    final publicURLs =
        (map['publicURLs'] == null || map['publicURLs'].length == 0)
            ? <PublicURL>[]
            : List<PublicURL>.from(
                map['publicURLs'].map((x) => PublicURL.fromMap(x)),
              );
    return CollectionV2(
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
