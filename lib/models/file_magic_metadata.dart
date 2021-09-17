import 'dart:convert';

const kVisibilityVisible = 0;
const kVisibilityArchive = 1;

class FileMagicMetadata {
  // 0 -> visible
  // 1 -> archived
  // 2 -> hidden etc?
  int visibility;

  FileMagicMetadata({this.visibility});

  factory FileMagicMetadata.fromEncodedJson(String encodedJson) =>
      FileMagicMetadata.fromJson(jsonDecode(encodedJson));

  factory FileMagicMetadata.fromJson(dynamic json) =>
      FileMagicMetadata.fromMap(json);

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map['visibility'] = visibility;
    return map;
  }

  factory FileMagicMetadata.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return FileMagicMetadata(
      visibility: map['visibility'] ?? 0,
    );
  }
}
