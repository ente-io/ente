import 'dart:typed_data';

import "package:json_annotation/json_annotation.dart";

class Uint8ListConverter implements JsonConverter<Uint8List, List<int>> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(List<int>? json) {
    return json == null ? Uint8List(0) : Uint8List.fromList(json);
  }

  @override
  List<int> toJson(Uint8List object) {
    return object.toList();
  }
}
