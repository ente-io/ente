import 'dart:convert';

import 'package:flutter/material.dart';
import "package:photos/models/api/entity/type.dart";

@immutable
class EntityKey {
  final int userID;
  final String encryptedKey;
  final EntityType type;
  final String header;
  final int createdAt;

  const EntityKey(
    this.userID,
    this.encryptedKey,
    this.header,
    this.createdAt,
    this.type,
  );

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'type': type.name,
      'encryptedKey': encryptedKey,
      'header': header,
      'createdAt': createdAt,
    };
  }

  factory EntityKey.fromMap(Map<String, dynamic> map) {
    return EntityKey(
      map['userID']?.toInt() ?? 0,
      map['encryptedKey']!,
      map['header']!,
      map['createdAt']?.toInt() ?? 0,
      entityTypeFromString(map['type']!),
    );
  }

  String toJson() => json.encode(toMap());

  factory EntityKey.fromJson(String source) =>
      EntityKey.fromMap(json.decode(source));
}
