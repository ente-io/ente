import "dart:convert";

import 'package:photos/models/metadata/common_keys.dart';

const editTimeKey = 'editedTime';
const editNameKey = 'editedName';
const captionKey = "caption";
const uploaderNameKey = "uploaderName";
const widthKey = 'w';
const heightKey = 'h';
const latKey = "lat";
const longKey = "long";
const motionVideoIndexKey = "mvi";

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
      visibility: map[magicKeyVisibility] ?? visibleVisibility,
    );
  }
}

class PubMagicMetadata {
  int? editedTime;
  String? editedName;
  String? caption;
  String? uploaderName;
  int? w;
  int? h;
  double? lat;
  double? long;

  // Motion Video Index. Positive value (>0) indicates that the file is a motion
  // photo
  int? mvi;

  PubMagicMetadata({
    this.editedTime,
    this.editedName,
    this.caption,
    this.uploaderName,
    this.w,
    this.h,
    this.lat,
    this.long,
    this.mvi,
  });

  factory PubMagicMetadata.fromEncodedJson(String encodedJson) =>
      PubMagicMetadata.fromJson(jsonDecode(encodedJson));

  factory PubMagicMetadata.fromJson(dynamic json) =>
      PubMagicMetadata.fromMap(json);

  static fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    return PubMagicMetadata(
      editedTime: map[editTimeKey],
      editedName: map[editNameKey],
      caption: map[captionKey],
      uploaderName: map[uploaderNameKey],
      w: map[widthKey],
      h: map[heightKey],
      lat: map[latKey],
      long: map[longKey],
      mvi: map[motionVideoIndexKey],
    );
  }
}
