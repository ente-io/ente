// @dart=2.9

import 'dart:convert';

const kVisibilityVisible = 0;
const kVisibilityArchive = 1;

const kMagicKeyVisibility = 'visibility';

const kPubMagicKeyEditedTime = 'editedTime';
const kPubMagicKeyEditedName = 'editedName';

class MagicMetadata {
  // 0 -> visible
  // 1 -> archived
  // 2 -> hidden etc?
  int visibility;

  MagicMetadata({this.visibility});

  factory MagicMetadata.fromEncodedJson(String encodedJson) =>
      MagicMetadata.fromJson(jsonDecode(encodedJson));

  factory MagicMetadata.fromJson(dynamic json) => MagicMetadata.fromMap(json);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map[kMagicKeyVisibility] = visibility;
    return map;
  }

  factory MagicMetadata.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;
    return MagicMetadata(
      visibility: map[kMagicKeyVisibility] ?? kVisibilityVisible,
    );
  }
}

class PubMagicMetadata {
  int editedTime;
  String editedName;

  PubMagicMetadata({this.editedTime, this.editedName});

  factory PubMagicMetadata.fromEncodedJson(String encodedJson) =>
      PubMagicMetadata.fromJson(jsonDecode(encodedJson));

  factory PubMagicMetadata.fromJson(dynamic json) =>
      PubMagicMetadata.fromMap(json);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map[kPubMagicKeyEditedTime] = editedTime;
    map[kPubMagicKeyEditedName] = editedName;
    return map;
  }

  factory PubMagicMetadata.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;
    return PubMagicMetadata(
      editedTime: map[kPubMagicKeyEditedTime],
      editedName: map[kPubMagicKeyEditedName],
    );
  }
}

class CollectionMagicMetadata {
  // 0 -> visible
  // 1 -> archived
  // 2 -> hidden etc?
  int visibility;

  CollectionMagicMetadata({this.visibility});

  factory CollectionMagicMetadata.fromEncodedJson(String encodedJson) =>
      CollectionMagicMetadata.fromJson(jsonDecode(encodedJson));

  factory CollectionMagicMetadata.fromJson(dynamic json) =>
      CollectionMagicMetadata.fromMap(json);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map[kMagicKeyVisibility] = visibility;
    return map;
  }

  factory CollectionMagicMetadata.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;
    return CollectionMagicMetadata(
      visibility: map[kMagicKeyVisibility] ?? kVisibilityVisible,
    );
  }
}
