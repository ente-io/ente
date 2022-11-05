import 'dart:convert';

const visibilityVisible = 0;
const visibilityArchive = 1;

const magicKeyVisibility = 'visibility';

const pubMagicKeyEditedTime = 'editedTime';
const pubMagicKeyEditedName = 'editedName';
const pubMagicKeyCaption = "caption";

class MagicMetadata {
  // 0 -> visible
  // 1 -> archived
  // 2 -> hidden etc?
  int visibility;

  MagicMetadata({required this.visibility});

  factory MagicMetadata.fromEncodedJson(String encodedJson) =>
      MagicMetadata.fromJson(jsonDecode(encodedJson));

  factory MagicMetadata.fromJson(dynamic json) => MagicMetadata.fromMap(json);

  static fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    return MagicMetadata(
      visibility: map[magicKeyVisibility] ?? visibilityVisible,
    );
  }
}

class PubMagicMetadata {
  int? editedTime;
  String? editedName;
  String? caption;

  PubMagicMetadata({this.editedTime, this.editedName, this.caption});

  factory PubMagicMetadata.fromEncodedJson(String encodedJson) =>
      PubMagicMetadata.fromJson(jsonDecode(encodedJson));

  factory PubMagicMetadata.fromJson(dynamic json) =>
      PubMagicMetadata.fromMap(json);

  static fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    return PubMagicMetadata(
      editedTime: map[pubMagicKeyEditedTime],
      editedName: map[pubMagicKeyEditedName],
      caption: map[pubMagicKeyCaption],
    );
  }
}

class CollectionMagicMetadata {
  // 0 -> visible
  // 1 -> archived
  // 2 -> hidden etc?
  int visibility;

  CollectionMagicMetadata({required this.visibility});

  factory CollectionMagicMetadata.fromEncodedJson(String encodedJson) =>
      CollectionMagicMetadata.fromJson(jsonDecode(encodedJson));

  factory CollectionMagicMetadata.fromJson(dynamic json) =>
      CollectionMagicMetadata.fromMap(json);

  static fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    return CollectionMagicMetadata(
      visibility: map[magicKeyVisibility] ?? visibilityVisible,
    );
  }
}
