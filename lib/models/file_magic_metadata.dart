import 'dart:convert';

class FileMagicMetadata {
  // 0 -> visible
  // 1 -> archived
  // 2 -> hidden etc?
  int visibility;

  FileMagicMetadata({this.visibility});

  FileMagicMetadata.fromEncodedJson(String encodedJson) {
    FileMagicMetadata.fromJson(jsonDecode(encodedJson));
  }

  FileMagicMetadata.fromJson(dynamic json) {
    visibility = json['visibility'] ?? 0;
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map['visibility'] = visibility;
    return map;
  }
}
