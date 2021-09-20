import 'dart:convert';

const kVisibilityVisible = 0;
const kVisibilityArchive = 1;

const kMagicKeyVisibility = 'visibility';

class MagicMetadata {
  // 0 -> visible
  // 1 -> archived
  // 2 -> hidden etc?
  int visibility;

  MagicMetadata({this.visibility});

  factory MagicMetadata.fromEncodedJson(String encodedJson) =>
      MagicMetadata.fromJson(jsonDecode(encodedJson));

  factory MagicMetadata.fromJson(dynamic json) =>
      MagicMetadata.fromMap(json);

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
